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
    
    //csuci coordinates
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
    
    @State private var position: MapCameraPosition
    
    init() {
        position = MapCameraPosition.region(defaultRegion)
    }

    var body: some View {
        // Load until retrieval done or failure
        if mapViewModel.isLoading {
            Text("Loading campus locations...")
        }else {
            Map(position: $position) {
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
    
    private var mapPosition: MapCameraPosition {
        if let userCoord = locationManager.userLocation {
            return .region(MKCoordinateRegion(
                center: userCoord,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.008,
                    longitudeDelta: 0.008
                )
            ))
        } else {
            return .region(defaultRegion)
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
