//
//  AssignmentsCardView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 5/9/26.
//

import Foundation
import SwiftUI

struct AssignmentsCardView: View {
    @EnvironmentObject var viewModel: AssignmentsViewModel
    @Environment(\.colorScheme) var colorScheme
    
    private var peachBackground: Color {
        colorScheme == .dark ? Color.channelClay.opacity(0.25) : Color(red: 0.99, green: 0.91, blue: 0.85)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(Color.channelClay)

                Text("Assignments")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.channelClay)

                Spacer()

                NavigationLink {
                    AssignmentsListView()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.channelClay.opacity(0.6))
                }
            }

            Divider()
                .background(Color.channelClay.opacity(0.2))

            if viewModel.activeTodaysAssignments.isEmpty {
                Text("No assignments today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.activeTodaysAssignments.prefix(3)) { assignment in
                    Text(assignment.title)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                if colorScheme == .dark {
                    Color(.secondarySystemGroupedBackground)
                }
                peachBackground
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.07), radius: 8, x: 0, y: 4)
    }
}
