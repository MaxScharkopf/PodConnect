//
//  MapView.swift
//  PodConnect
//
//
//
import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var mapViewModel = MapViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var autoCenterEnabled: Bool = false
    @State private var userMovingMap = false
    @State private var showSearch = false
    @State private var activeCategories: Set<String> = []
    @State private var selectedPin: MapPin? = nil
    @State private var searchedLocation: MapLocation? = nil
    @State private var route: MKRoute?
    @State private var isCalculatingRoute = false
    @State private var routeError: String?
    @State private var isTripActive = false
    @State private var tripEndDate: Date?
    @State private var destinationName: String?
    @State private var showingAddPinSheet = false
    @State private var visibleRegion: MKCoordinateRegion?

    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.1647, longitude: -119.0426),
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )
    )
    
    private let followSpan = MKCoordinateSpan(
        latitudeDelta: 0.0015,
        longitudeDelta: 0.0015
    )

    // CSUCI coordinates for default centering
    private let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 34.1647,
            longitude: -119.0426
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.008,
            longitudeDelta: 0.008
        )
    )

    // Locations filtered by active categories (empty = show all)
    private var filteredPins: [MapPin] {
        guard !activeCategories.isEmpty else { return mapViewModel.allPins }
        return mapViewModel.allPins.filter { pin in
            guard let category = pin.category else { return false }
            return activeCategories.contains(category)
        }
    }

    var body: some View {
        MapReader { proxy in
            ZStack {
                Map(position: $mapPosition, selection: $selectedPin) {
                    UserAnnotation()
                    
                    ForEach(filteredPins) { pin in
                        let style = markerStyle(for: pin.category ?? "")
                        
                        if pin.category != "Classrooms" {
                            Marker(
                                pin.name,
                                systemImage: style.icon,
                                coordinate: pin.coordinate
                            )
                            .tint(pin.pinType == "user" ? .orange : style.color)
                            .tag(pin)
                        }
                    }
                    
                    if let route {
                        MapPolyline(route.polyline)
                            .stroke(.blue, lineWidth: 6)
                    }
                }
                
                // Tracks visible region for center
                .onMapCameraChange { context in
                    visibleRegion = context.region
                }
                
                // Toggle auto center off when user scrolls
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !userMovingMap {
                                userMovingMap = true
                                autoCenterEnabled = false
                            }
                        }
                        .onEnded { _ in
                            userMovingMap = false
                        }
                )
                // Auto centering map if toggled
                .onChange(of: "\(locationManager.userLocation?.latitude ?? 0),\(locationManager.userLocation?.longitude ?? 0)") { _, _ in
                    guard autoCenterEnabled else { return }
                    guard let coord = locationManager.userLocation else { return }
                    centerMap(on: coord, span: followSpan)
                }
                // Fly to location when selected from search
                .onChange(of: searchedLocation?.id) { _, _ in
                    guard let location = searchedLocation else { return }
                    
                    autoCenterEnabled = false
                    
                    centerMap(
                        on: CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng),
                        span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                    )
                    
                    searchedLocation = nil
                }
                
                if isCalculatingRoute {
                    Text("Calculating route...")
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                if isTripActive {
                    VStack {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Directions to: \(destinationName ?? "Destination")")
                                    .font(.headline)
                                
                                if let route {
                                    Text("Estimated time: \(Int(route.expectedTravelTime / 60)) min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button("End Trip") {
                                endTrip()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        Spacer()
                    }
                }
                
                // Search button, autocenter overlay, new pin button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack (spacing: 12) {
                            
                            // Add a user pin
                            Button(action: {showingAddPinSheet = true}) {
                                mapButton(icon: "mappin.and.ellipse")
                            }
                            .sheet(isPresented: $showingAddPinSheet) {
                                AddPinSheet { name, subtitle in
                                    let center = currentMapCenter()
                                    
                                    Task {
                                        await mapViewModel.addUserPin(
                                            name: name,
                                            subtitle: subtitle,
                                            coordinate: center,
                                            ownerUserId: nil
                                        )
                                    }
                                }
                            }
                            
                            // Toggle auto center
                            Button(action: {
                                if autoCenterEnabled {
                                    autoCenterEnabled = false
                                } else {
                                    autoCenterEnabled = true
                                    
                                    if let coord = locationManager.userLocation {
                                        centerMap(on: coord, span: followSpan)
                                    }
                                }
                            }) {
                                mapButton(icon: autoCenterEnabled ? "location.fill" : "location")
                                
                            }
                            
                            // Search button
                            Button(action: { showSearch = true }) {
                                mapButton(icon: "magnifyingglass")
                                
                            }
                            .sheet(isPresented: $showSearch) {
                                sBar(
                                    locations: mapViewModel.mapLocations,
                                    categories: mapViewModel.locationCategories,
                                    activeCategories: $activeCategories,
                                    selectedLocation: $searchedLocation
                                )
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
                if mapViewModel.isLoading {
                    Text("Loading campus locations...")
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .sheet(item: $selectedPin) { pin in
            LocationDetailSheet(
                pin: pin,
                onDirections: {
                    Task {
                        await getDirections(to: pin)
                    }
                },
                onDelete: pin.pinType == "user" ? {
                    Task {
                        if let id = pin.id {
                            await mapViewModel.deleteUserPin(id: id)
                            selectedPin = nil
                        }
                    }
                } : nil
            )
        }
        .alert("Error",
            isPresented: Binding(
                get: { mapViewModel.errorMessage != nil },
                set: { _ in mapViewModel.errorMessage = nil }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(mapViewModel.errorMessage ?? "") Cannot load map locations.")
        }
    }

    // Auto center helper
    func centerMap(on coord: CLLocationCoordinate2D, span: MKCoordinateSpan? = nil) {
        withAnimation(.smooth(duration: 1.0)) {
            mapPosition = .region(
                MKCoordinateRegion(
                    center: coord,
                    span: span ?? defaultRegion.span
                )
            )
        }
    }
    
    // Get center of the map for creating a pin
    func currentMapCenter() -> CLLocationCoordinate2D {
        visibleRegion?.center ?? defaultRegion.center
    }
    
    func markerStyle(for category: String) -> (icon: String, color: Color) {
        switch category {
        case "Recreation Areas":
            return ("american.football.fill", .green)
        case "Open Areas":
            return ("person.2.fill", .green)
        case "Buildings and Spaces":
            return ("building.2.fill", .blue)
        case "Gardens":
            return ("leaf.fill", .green)
        case "Bell Tower", "Bell Tower East", "Bell Tower West":
            return ("building.2.fill", .red)
        default:
            return ("mappin", .gray)
        }
    }
    
    func startTrip(to pin: MapPin, using route: MKRoute) {
        self.route = route
        isTripActive = true
        destinationName = pin.name
        tripEndDate = Date().addingTimeInterval(route.expectedTravelTime)

        selectedPin = nil
        autoCenterEnabled = false

        // Zooms out to show whole path
        withAnimation(.smooth(duration: 1.0)) {
            mapPosition = .rect(route.polyline.boundingMapRect)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard isTripActive else { return }
            autoCenterEnabled = true

            if let coord = locationManager.userLocation {
                centerMap(on: coord, span: followSpan)
            }
        }
    }
    
    func getDirections(to pin: MapPin) async {
        guard let userCoord = locationManager.userLocation else {
            routeError = "User location is unavailable."
            return
        }

        isCalculatingRoute = true
        route = nil
        routeError = nil

        let request = MKDirections.Request()

        request.source = MKMapItem(
            location: CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude),
            address: nil
        )

        request.destination = MKMapItem(
            location: CLLocation(latitude: pin.latitude, longitude: pin.longitude),
            address: nil
        )

        request.transportType = .walking
        request.requestsAlternateRoutes = false

        do {
            let response = try await MKDirections(request: request).calculate()

            guard let firstRoute = response.routes.first else {
                routeError = "No route found."
                isCalculatingRoute = false
                return
            }

            startTrip(to: pin, using: firstRoute)
        } catch {
            routeError = error.localizedDescription
        }

        isCalculatingRoute = false
    }
    
    func endTrip() {
        route = nil
        isTripActive = false
        tripEndDate = nil
        destinationName = nil
        autoCenterEnabled = false
        selectedPin = nil
    }
}

// Helper function keep map buttons consistent
func mapButton(icon: String, isActive: Bool = false) -> some View {
    Image(systemName: icon)
        .font(.system(size: 22))
        .frame(width: 44, height: 44)
        .background(Color.white.opacity(0.6))
        .clipShape(Circle())
        .shadow(radius: 5)
}

struct sBar: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sText = ""
    let locations: [MapLocation]
    let categories: [Int: String]
    @Binding var activeCategories: Set<String>
    @Binding var selectedLocation: MapLocation?

    // Unique category names for filter chips
    private var availableCategories: [String] {
        Array(Set(categories.values)).filter { $0 != "Classrooms" }.sorted()
    }

    // Locations filtered by search text
    private var searchResults: [MapLocation] {
        guard !sText.isEmpty else { return [] }
        return locations.filter { $0.name.localizedCaseInsensitiveContains(sText) }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        // Clear button — only shows when filters are active
                        if !activeCategories.isEmpty {
                            Button(action: { activeCategories.removeAll() }) {
                                Text("Clear")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.15))
                                    .foregroundColor(.red)
                                    .clipShape(Capsule())
                            }
                        }

                        ForEach(availableCategories, id: \.self) { category in
                            let isActive = activeCategories.contains(category)
                            Button(action: {
                                if isActive {
                                    activeCategories.remove(category)
                                } else {
                                    activeCategories.insert(category)
                                }
                            }) {
                                Text(category)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isActive ? Color.blue : Color(.systemGray5))
                                    .foregroundColor(isActive ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                Divider()

                // Search results
                if sText.isEmpty {
                    Spacer()
                    Text("Search for a campus location")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else if searchResults.isEmpty {
                    Spacer()
                    Text("No results for \"\(sText)\"")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    List(searchResults) { location in
                        Button(action: {
                            selectedLocation = location
                            dismiss()
                        }) {
                            VStack(alignment: .leading) {
                                Text(location.name)
                                    .foregroundColor(.primary)
                                if let catId = location.catId, let category = categories[catId] {
                                    Text(category)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .toolbar {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .searchable(text: $sText, prompt: "Search campus locations")
        .presentationDetents([.medium, .large])
    }
}

struct LocationDetailSheet: View {
    let pin: MapPin
    let onDirections: () -> Void
    let onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(pin.name)
                .font(.title2)
                .bold()

            if let category = pin.category {
                Text(category)
                    .foregroundColor(.secondary)
            }

            if let subtitle = pin.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Input description here")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button("Get Directions") {
                onDirections()
            }
            .buttonStyle(.borderedProminent)
            
            if let onDelete {
                Button("Delete Pin", role: .destructive) {
                    onDelete()
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
        .presentationDetents([.height(240)])
        .presentationDragIndicator(.visible)
    }
}

struct AddPinSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var subtitle = ""
    
    let onSave: (String, String?) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Pin name", text: $name)
                TextField("Description", text: $subtitle)
            }
            .navigationTitle("New Pin")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, subtitle.isEmpty ? nil : subtitle)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.height(220)])         
        .presentationDragIndicator(.visible)
    }
}


#Preview {
    MapView()
}
