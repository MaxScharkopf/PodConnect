//
//  ColorScheme.swift
//  PodConnect
//
//  Created by Kaitlyn Cox on 4/1/26.
//


import SwiftUI

struct ColorScheme: View {
    var body: some View {
        let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)
        let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
        
        
        ZStack {
            HStack{
                Image(systemName: "square.fill") // secondary accent color
                    .font(.system(size: 100))
                    .foregroundStyle(ChannelClay)
                
                
                Image(systemName: "square.fill") // main accent color
                    .font(.system(size: 100))
                    .foregroundStyle(IslandsBlue)
            }
          
        }
    }
}



#Preview{
    ColorScheme()
}
