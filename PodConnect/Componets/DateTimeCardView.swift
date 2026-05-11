//
//  DateTimeCardView.swift
//  PodConnect
//

import SwiftUI
import Combine

struct DateTimeCardView: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)

    private var dayOfWeek: String {
        now.formatted(.dateTime.weekday(.wide)).uppercased()
    }
    private var monthDay: String {
        now.formatted(.dateTime.month(.wide).day())
    }
    private var timeString: String {
        now.formatted(.dateTime.hour().minute())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dayOfWeek)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.7))

            Text(monthDay)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(timeString)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(IslandsBlue)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .onReceive(timer) { t in now = t }
    }
}
