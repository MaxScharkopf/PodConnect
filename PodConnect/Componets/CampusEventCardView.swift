//
//  CampusEventCardView.swift
//  PodConnect
//

import SwiftUI

struct CampusEventCardView: View {
    private let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
         
            Text("NATIONAL DAY")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.7))

            Text(todayNationalDay() ?? "No National Day Today")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            HStack {
                Spacer()
                Image(systemName: "party.popper.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(ChannelClay)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}
