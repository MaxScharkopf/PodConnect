//
//  MapView.swift
//  PodConnect
//
//
//
import SwiftUI
import MapKit

struct MapView: View {
    
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

       var body: some View {
           Map(position: .constant(mapPosition))
               .ignoresSafeArea()
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
   }

   #Preview {
       MapView()
   }
