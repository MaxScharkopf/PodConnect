//
//  MapView.swift
//  PodConnect
//
//
//
import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var mapViewModel: MapViewModel
    @StateObject private var locationManager = LocationManager()
    @StateObject private var pinShareViewModel: PinShareViewModel
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
    @State private var showingPinShareRequests = false
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var isAddingPin = false
    @State private var editingPin: MapPin?
    @State private var pendingPinCoordinate: CLLocationCoordinate2D?
    @State private var friends: [UserInfo] = []
    @State private var pendingShareReceiverUIDs: [String] = []
    private let friendRepository: FriendRepository

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
    
    init(authService: AuthService, firestoreService: FirestoreService) {
        
        let mapRepository = MapRepository(
            firestoreService: firestoreService,
            authService: authService
        )
        
        let friendRepository = FriendRepository(
            firestoreService: firestoreService
        )
        
        let pinShareRepository = PinShareRepository(
            firestoreService: firestoreService
        )
        
        self.friendRepository = friendRepository

        _mapViewModel = StateObject(
            wrappedValue: MapViewModel(mapRepository: mapRepository, friendRepository: friendRepository)
        )
        
        _pinShareViewModel = StateObject(
            wrappedValue: PinShareViewModel(
                pinShareRepository: pinShareRepository,
                authService: authService
            )
        )
    }

    // Core campus buildings shown by default when no filters are active
    private let coreBuildingNames: Set<String> = [
        "ISL - Islands Cafe",
        "SUB - Student Union Building",
        "BEL - Bell Tower",
        "GAT - Gateway Hall",
        "SIE - Sierra Hall",
        "NOR - Del Norte Hall",
        "BRO - Broome Library"
    ]

    private func isCoreBuilding(_ pin: MapPin) -> Bool {
        coreBuildingNames.contains(pin.name)
    }

    // When no category filters are active, show only core buildings + user pins.
    // When filters are active, show matching campus pins + user pins.
    private var filteredPins: [MapPin] {
        if activeCategories.isEmpty {
            return mapViewModel.allPins.filter { pin in
                pin.pinType == "user" || isCoreBuilding(pin)
            }
        }
        return mapViewModel.allPins.filter { pin in
            pin.pinType == "user" || (pin.category.map { activeCategories.contains($0) } ?? false)
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
                    
                    
                    if let coord = pendingPinCoordinate {
                        Marker("New Pin", coordinate: coord)
                            .tint(.orange)
                    }
                }
                .onTapGesture { point in
                    guard isAddingPin else {return}
                    
                    if let coordinate = proxy.convert(point, from: .local) {
                        pendingPinCoordinate = coordinate
                        showingAddPinSheet = true
                        isAddingPin = false
                    }
                }
                .overlay(alignment: .top) {
                    if isAddingPin {
                        Text("Tap map to place a pin")
                            .padding()
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                            Button(action: {isAddingPin = true}) {
                                mapButton(icon: "mappin.and.ellipse")
                            }
                            .sheet(
                                isPresented: $showingAddPinSheet,
                                onDismiss: {
                                    isAddingPin = false
                                    pendingPinCoordinate = nil
                                }
                                ) {
                                AddPinSheet(
                                    pin: nil,
                                    friends: friends,
                                    onSave: { name, subtitle, selectedFriendIDs in
                                        let center = pendingPinCoordinate ?? currentMapCenter()
                                        
                                        Task {
                                            if let newPin = await mapViewModel.addUserPin(
                                                name: name,
                                                subtitle: subtitle,
                                                coordinate: center,
                                                sharedWith: []
                                            ), let pinId = newPin.id {
                                                for uid in selectedFriendIDs {
                                                    await pinShareViewModel.sendRequest(
                                                        pinId: pinId,
                                                        pinName: name,
                                                        receiverUid: uid
                                                    )
                                                }
                                            }
                                        }
                                        pendingPinCoordinate = nil
                                    }
                                )
                            }
                            
                            // View pin requests
                            Button(action: {showingPinShareRequests = true}) {
                                mapButton(icon: "person.crop.circle.badge.plus")
                            }
                            .sheet(isPresented: $showingPinShareRequests) {
                                PinShareRequestsSheet(
                                    requests: pinShareViewModel.incomingRequests,
                                    onAccept: { request in
                                        Task {
                                            await pinShareViewModel.acceptRequest(request)
                                        }
                                    },
                                    onDecline: { request in
                                        Task {
                                            await pinShareViewModel.declineRequest(request)
                                        }
                                    }
                                )
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
            .task {
                await loadFriends()
                await pinShareViewModel.loadIncomingRequests()
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
                } : nil,
                onEdit: pin.pinType == "user" ? {
                    Task {
                        selectedPin = nil
                        
                        if let pinId = pin.id {
                            do {
                                pendingShareReceiverUIDs = try await pinShareViewModel.fetchPendingReceiverUIDs(for: pinId)
                            } catch {
                                pendingShareReceiverUIDs = []
                            }
                        } else {
                            pendingShareReceiverUIDs = []
                        }
                        
                        editingPin = pin
                    }
                } : nil
            )
        }
        .sheet(item: $editingPin) { pin in
            AddPinSheet(
                pin: pin,
                friends: friends,
                initialSelectedFriendIDs: Set(pendingShareReceiverUIDs),
                onSave: { name, subtitle, selectedFriendIDs in
                    guard let id = pin.id else { return }

                    Task {
                        let oldShared = Set(pin.sharedWith ?? [])
                        let selected = Set(selectedFriendIDs)

                        let keptShared = Array(oldShared.intersection(selected))
                        let newRequestUIDs = Array(selected.subtracting(oldShared))

                        await mapViewModel.updateUserPin(
                            id: id,
                            name: name,
                            subtitle: subtitle,
                            sharedWith: keptShared
                        )

                        for uid in newRequestUIDs {
                            await pinShareViewModel.sendRequest(
                                pinId: id,
                                pinName: name,
                                receiverUid: uid
                            )
                        }

                        editingPin = nil
                        selectedPin = nil
                        pendingShareReceiverUIDs = []
                    }
                }
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
    
    func loadFriends() async {
        do {
            friends = try await friendRepository.fetchFriends()
            print("Loaded friends")
        }
        catch {
            print("Faild to load friends")
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
                        // Clear button — only shows when filters are active; returns to default core-buildings view
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
        .presentationDetents([.height(270), .medium])
    }
}

struct LocationDetailSheet: View {
    let pin: MapPin
    let onDirections: () -> Void
    let onDelete: (() -> Void)?
    let onEdit: (() -> Void)?

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(pin.name)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            if let category = pin.category {
                Text(category)
                    .foregroundColor(.secondary)
            }

            if let subtitle = pin.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Input description here")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("Get Directions") {
                onDirections()
            }
            .buttonStyle(.borderedProminent)
            
            if let onEdit {
                Button("Edit Pin") {
                    onEdit()
                }
                .buttonStyle(.bordered)
            }
            
            if let onDelete {
                Button("Delete Pin", role: .destructive) {
                    onDelete()
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding(.top, 20)
        .presentationDetents([.height(270), .medium])
        .fixedSize(horizontal: false, vertical: false
        )
        .presentationDragIndicator(.visible)
    }
}

struct AddPinSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var subtitle: String
    @State private var selectedFriendIDs: Set<String>

    let pin: MapPin?
    let friends: [UserInfo]
    let onSave: (String, String?, [String]) -> Void

    init(
        pin: MapPin? = nil,
        friends: [UserInfo],
        initialSelectedFriendIDs: Set<String> = [],
        onSave: @escaping (String, String?, [String]) -> Void
    ) {
        self.pin = pin
        self.friends = friends
        self.onSave = onSave

        let accepted = Set(pin?.sharedWith ?? [])
        let combinedSelected = accepted.union(initialSelectedFriendIDs)

        _name = State(initialValue: pin?.name ?? "")
        _subtitle = State(initialValue: pin?.subtitle ?? "")
        _selectedFriendIDs = State(initialValue: combinedSelected)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pin Details") {
                    TextField("Pin name", text: $name)
                    TextField("Description", text: $subtitle, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Share With Friends") {
                    Menu {
                        ForEach(friends, id: \.id) { friend in
                            if let uid = friend.id {
                                Button {
                                    toggleFriend(uid)
                                } label: {
                                    if selectedFriendIDs.contains(uid) {
                                        Label(friend.username, systemImage: "checkmark")
                                    } else {
                                        Text(friend.username)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Shared With")
                            Spacer()
                            Text(sharedFriendsText)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !selectedFriendIDs.isEmpty {
                        ForEach(selectedFriends, id: \.id) { friend in
                            Text(friend.username)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(pin == nil ? "New Pin" : "Edit Pin")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(pin == nil ? "Save" : "Update") {
                        onSave(
                            name.trimmingCharacters(in: .whitespacesAndNewlines),
                            subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? nil
                                : subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
                            Array(selectedFriendIDs)
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.height(300), .medium])
        .presentationDragIndicator(.visible)
    }

    private var selectedFriends: [UserInfo] {
        friends.filter { friend in
            guard let uid = friend.id else { return false }
            return selectedFriendIDs.contains(uid)
        }
    }

    private func toggleFriend(_ uid: String) {
        if selectedFriendIDs.contains(uid) {
            selectedFriendIDs.remove(uid)
        } else {
            selectedFriendIDs.insert(uid)
        }
    }

    private var sharedFriendsText: String {
        selectedFriendIDs.isEmpty ? "None" : "\(selectedFriendIDs.count) selected"
    }
}

struct PinShareRequestsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let requests: [PinShareRequest]
    let onAccept: (PinShareRequest) -> Void
    let onDecline: (PinShareRequest) -> Void
    
    var body: some View {
        NavigationStack {
            Group {
                if requests.isEmpty {
                    VStack(spacing: 12) {
                        Text("No Pin Share Requests")
                            .font(.headline)
                        Text("You don’t have any pending requests right now.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List(requests) { request in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(request.pinName)
                                .font(.headline)
                            
                            Text("\(request.senderName) wants to share this pin with you")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Button("Accept") {
                                    onAccept(request)
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("Decline", role: .destructive) {
                                    onDecline(request)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Pin Requests")
            .toolbar {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    MapView(authService: AuthService(firestoreService: FirestoreService()), firestoreService: FirestoreService())
}
