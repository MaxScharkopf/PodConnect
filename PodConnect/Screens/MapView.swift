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
    @State private var pauseUntil: Date? = nil
    @State private var isAutoCentering: Bool = false
    
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.1647, longitude: -119.0426),
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )
    )
    
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
           Map(position: $mapPosition) {
               UserAnnotation()
           }
           
           // Add delay if user scrolls the map
           .onMapCameraChange { _ in
                   guard !isAutoCentering else { return }
                   pauseUntil = Date().addingTimeInterval(3)
           }
           
           // Continuously center map around user
           .onChange(of: locationManager.userLocation?.latitude) { _, _ in
               guard let coord = locationManager.userLocation else { return }
               
               if let pauseUntil, Date() < pauseUntil { return }
               
               isAutoCentering = true
               mapPosition = .region(MKCoordinateRegion(center: coord, span: defaultRegion.span))
               
               DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                   isAutoCentering = false
               }
           }
           .ignoresSafeArea()
       }
    
   }

   #Preview {
       MapView()
   }
