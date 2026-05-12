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
    
    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    private let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)
    private let peachBackground = Color(red: 0.99, green: 0.91, blue: 0.85)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(ChannelClay)

                Text("Assignments")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(ChannelClay)

                Spacer()

                NavigationLink {
                    AssignmentsListView()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(ChannelClay.opacity(0.6))
                }
            }

            Divider()
                .background(ChannelClay.opacity(0.2))

            if viewModel.todaysAssignments.isEmpty {
                Text("No assignments today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.todaysAssignments.prefix(3)) { assignment in
                    HStack(spacing: 6) {
                        Button {
                            Task {
                                await viewModel.toggleCompleted(assignment)
                            }
                        } label: {
                            Image(systemName: assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundColor(ChannelClay)
                        }
                        .buttonStyle(.plain)

                        Text(assignment.title)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .strikethrough(assignment.isCompleted)
                            .foregroundColor(assignment.isCompleted ? .secondary : .primary)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(peachBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
    }
}
