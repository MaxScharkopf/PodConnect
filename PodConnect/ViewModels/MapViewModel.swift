//
//  MapViewModel.swift
//  PodConnect
//
//  Created by Noah Hester on 3/11/26.
//

import Combine
import Foundation

class MapViewModel: ObservableObject {
    @Published var mapData: MapResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() async {
        // Fetch the locations on initiation
        await fetchMapLocations()
    }
    
    func fetchMapLocations() async {
        self.isLoading = true
        
        let mapURL = URL(string: "https://api.concept3d.com/categories/4034,39247,24292,24293,75941,75942,75943,75944?map=502&batch&children&key=0001085cc708b9cef47080f064612ca5")!
        
        URLSession.shared.dataTask(with: mapURL) { data,_,_ in
            let response = try! JSONDecoder().decode(MapResponse.self, from: data!)
            
            DispatchQueue.main.async {
                self.mapData = response
                self.isLoading = false
            }
        }
        .resume()
    }
}
