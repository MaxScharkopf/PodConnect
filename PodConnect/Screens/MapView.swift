//
//  MapView.swift
//  PodConnect
//
//
//
import SwiftUI
import MapKit

struct MapView: View {
    
    //csuci coordinates
    @State private var position: MapCameraPosition = .region(
           MKCoordinateRegion(
               center: CLLocationCoordinate2D(
                   latitude: 34.1637,
                   longitude: -119.0429
               ),
               span: MKCoordinateSpan(
                   latitudeDelta: 0.005,
                   longitudeDelta: 0.005
               )
           )
       )

       var body: some View {
           Map(position: $position)
               .ignoresSafeArea()
       }
   }

   #Preview {
       MapView()
   }
