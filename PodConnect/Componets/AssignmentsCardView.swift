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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Assignments")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                NavigationLink {
                    AssignmentsListView()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.85))
                }
            }

            Divider()
                .background(.white.opacity(0.35))

            if viewModel.activeTodaysAssignments.isEmpty {
                Text("No assignments today")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            } else {
                ForEach(viewModel.activeTodaysAssignments.prefix(3)) { assignment in
                    Text(assignment.title)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(14)
        .frame(width: 170)
        .background(IslandsBlue)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}
