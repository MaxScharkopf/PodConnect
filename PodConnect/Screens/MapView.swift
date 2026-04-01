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
    @State private var selectedLocation: MapLocation? = nil

    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.1647, longitude: -119.0426),
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )
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
    private var filteredLocations: [MapLocation] {
        guard !activeCategories.isEmpty else { return mapViewModel.mapLocations }
        return mapViewModel.mapLocations.filter { location in
            guard let catId = location.catId,
                  let category = mapViewModel.locationCategories[catId] else { return false }
            return activeCategories.contains(category)
        }
    }

    var body: some View {
        ZStack {
            Map(position: $mapPosition) {
                UserAnnotation()

                ForEach(filteredLocations) { location in
                    if let category = mapViewModel.locationCategories[location.catId ?? 0] {
                        let style = markerStyle(for: category)
                        if category != "Classrooms" {
                            Marker(
                                location.name,
                                systemImage: style.icon,
                                coordinate: CLLocationCoordinate2D(
                                    latitude: location.lat,
                                    longitude: location.lng
                                )
                            )
                            .tint(style.color)
                        }
                    }
                }
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
                centerMap(on: coord)
            }
            // Fly to location when selected from search
            .onChange(of: selectedLocation?.id) { _, _ in
                guard let location = selectedLocation else { return }
                
                autoCenterEnabled = false
                
                centerMap(
                    on: CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng),
                    span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    selectedLocation = nil
                }
            }

            // Search button and autocenter overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack {
                        // Toggle auto center
                        Button(action: {
                            if autoCenterEnabled {
                                autoCenterEnabled = false
                            } else {
                                autoCenterEnabled = true

                                if let coord = locationManager.userLocation {
                                    centerMap(on: coord)
                                }
                            }
                        }) {
                            Image(systemName: autoCenterEnabled ? "location.fill" : "location")
                                .padding(10)
                                .font(.system(size: 25))
                                .background(Color.white.opacity(0.6))
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        
                        Button(action: { showSearch = true }) {
                            Image(systemName: "magnifyingglass")
                                .padding(10)
                                .font(.system(size: 25))
                                .background(Color.white.opacity(0.6))
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .sheet(isPresented: $showSearch) {
                            sBar(
                                locations: mapViewModel.mapLocations,
                                categories: mapViewModel.locationCategories,
                                activeCategories: $activeCategories,
                                selectedLocation: $selectedLocation
                            )
                        }
                        .padding(20)
                    }
                }
            }
            if mapViewModel.isLoading {
                Text("Loading campus locations...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
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

#Preview {
    MapView()
}
