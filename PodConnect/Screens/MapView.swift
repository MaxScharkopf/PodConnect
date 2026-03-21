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
    @State private var pauseUntil: Date? = nil
    @State private var isAutoCentering: Bool = false
    
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

    var body: some View {
        // Load until retrieval done or failure
        if mapViewModel.isLoading {
            Text("Loading campus locations...")
        }else {
            Map(position: $mapPosition) {
                // Add user location dot
                UserAnnotation()
                
                ForEach(mapViewModel.mapLocations) { location in
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
            // Add delay if user scrolls the map
            .onMapCameraChange(frequency: .continuous) { _ in
                guard !isAutoCentering else { return }
                pauseUntil = Date().addingTimeInterval(3)
            }
            // Continuously center map around user
            .onChange(of: "\(locationManager.userLocation?.latitude ?? 0),\(locationManager.userLocation?.longitude ?? 0)") { _, _ in
                guard let coord = locationManager.userLocation else { return }
                
                guard pauseUntil == nil || Date() >= pauseUntil! else { return }
                
                isAutoCentering = true
                
                // Animate the recentering for a smoother effect
                withAnimation(.smooth(duration: 1.0)) {
                    mapPosition = .region(MKCoordinateRegion(center: coord, span: defaultRegion.span))
                }
               
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isAutoCentering = false
                }
           }
            .ignoresSafeArea()
            // Show an error prompt if there is an error loading locations
            .alert("Error",
                isPresented: Binding(
                    get: { mapViewModel.errorMessage != nil },
                        // Clear the error on dismissal
                    set: { _ in mapViewModel.errorMessage = nil }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                // Print the error message
                Text("\(mapViewModel.errorMessage ?? "") Cannot load map locations.")
            }
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

#Preview {
    MapView()
}
