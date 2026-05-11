//
//    ToDoCardView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 5/9/26.
//

import Foundation
import SwiftUI

struct ToDoCardView: View {
    @ObservedObject var viewModel: ToDoViewModel

    private let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
    private let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            NavigationLink {
                ToDoListView(viewModel: viewModel)
            } label: {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundColor(ChannelClay)

                    Text("To-Do")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .buttonStyle(.plain)

            Divider()
                .background(.white.opacity(0.35))

            if viewModel.tasks.isEmpty {
                Text("No tasks yet")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            } else {
                ForEach(viewModel.tasks.prefix(3)) { task in
                    HStack(spacing: 8) {
                        Button {
                            viewModel.toggleTask(task)
                        } label: {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? ChannelClay : .white.opacity(0.8))
                        }
                        .buttonStyle(.plain)

                        Text(task.title)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .strikethrough(task.isCompleted)
                            .foregroundColor(.white.opacity(task.isCompleted ? 0.65 : 1))

                        Spacer()
                    }
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
