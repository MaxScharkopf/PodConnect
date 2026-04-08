//
//  TextBubbles.swift
//  PodConnect
//
//  Created by Kaitlyn Cox on 4/4/26.
//

import SwiftUI

struct TextBubbles: View {
    let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)
    let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    let message: Message
    let Sender: Bool
    var body: some View {
        HStack{
            if Sender {
                Spacer()
            }
            Text(message.content)
                .padding()
                .background(Sender ? IslandsBlue : ChannelClay)
                .foregroundStyle(Color.white)
                .cornerRadius(12)
            if !Sender {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
}
