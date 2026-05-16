//
//  ViewExtensions.swift
//  PodConnect
//
//  Created by Noah Hester on 4/19/26.
//

import SwiftUI
import MapKit

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

extension Color {
    static let islandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    static let channelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
