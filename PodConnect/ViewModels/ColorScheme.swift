//
//  ColorScheme.swift
//  PodConnect
//
//  Created by Kaitlyn Cox on 4/1/26.
//


import SwiftUI

struct ColorScheme: View {
    var body: some View {
        ZStack {
            HStack{
                Image(systemName: "square.fill") // secondary accent color
                    .font(.system(size: 100))
                    .foregroundStyle(Color.channelClay)
                
                
                Image(systemName: "square.fill") // main accent color
                    .font(.system(size: 100))
                    .foregroundStyle(Color.islandsBlue)
            }
          
        }
    }
}



#Preview{
    ColorScheme()
}
