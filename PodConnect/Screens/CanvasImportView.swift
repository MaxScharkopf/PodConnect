//
//  CanvasImportView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 5/9/26.
//

import Foundation
import SwiftUI

struct CanvasImportView: View {
    @EnvironmentObject var viewModel: AssignmentsViewModel

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    private let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Connect Canvas")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(IslandsBlue)

                    Text("Paste your Canvas calendar feed link to import assignments into PodConnect.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Canvas calendar feed link", text: $viewModel.canvasURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    Task {
                        await viewModel.loadAssignments()
                    }
                } label: {
                    Text("Import Assignments")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ChannelClay)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if !viewModel.assignments.isEmpty {
                    Text("Imported \(viewModel.assignments.count) assignments")
                        .font(.subheadline)
                        .foregroundColor(IslandsBlue)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
