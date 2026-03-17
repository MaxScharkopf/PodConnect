//
//  MapView.swift
//  PodConnect
//
//
//
import SwiftUI
import MapKit

struct MapView: View {
    @State private var show = false
    @State private var sT = 0
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
           ZStack{
               Map(position: .constant(mapPosition))   // dont mess with this
                   .ignoresSafeArea()       // or this
               VStack{
                   Spacer()
                   HStack{
                       Spacer()
                       Button(action:{sT = 1}){   // search button
                           Image(systemName: "magnifyingglass")
                               .padding(10)
                               .font(.system(size: 25))
                               .background(Color.white.opacity(0.6))
                               .clipShape(Circle())
                               .shadow(radius: 5)
                       }
                       .padding(20)
                       .onChange(of: sT){ old, new in  //when button is pressed
                           if new == 1 {
                               show = true
                               sT = old
                           }
                       }
                       .sheet(isPresented: $show){  // when 'show' = true
                           sBar()
                       }
                       .padding(5)
                   }
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
   }


struct sBar: View{    // creates a pull up screen for search bar
    @Environment(\.dismiss) private var dismiss
    @State private var sText = ""
    var body: some View{
        NavigationStack{
            VStack{
                Text("This is a test")  // Placeholder
            }
            .padding()
            .toolbar{
                Button(action: {dismiss()}){
                    Image(systemName: "xmark.app")
                        .clipShape(Circle())
                }
            }
        }
        .searchable(text: $sText) // on screen keyboard will pop up, not seen b/c laptop keyboard is used in sim
        .presentationDetents([.medium, .large])
    }
}

   #Preview {
       MapView()
   }
