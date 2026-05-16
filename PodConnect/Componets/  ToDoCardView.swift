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
    @Environment(\.colorScheme) var colorScheme

    private var mintBackground: Color {
        colorScheme == .dark ? Color.islandsBlue.opacity(0.25) : Color(red: 0.88, green: 0.96, blue: 0.92)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            NavigationLink {
                ToDoListView(viewModel: viewModel)
            } label: {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundColor(Color.islandsBlue)

                    Text("To-Do")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.islandsBlue)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color.islandsBlue.opacity(0.6))
                }
            }
            .buttonStyle(.plain)

            Divider()
                .background(Color.islandsBlue.opacity(0.2))

            if viewModel.tasks.isEmpty {
                Text("No tasks yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.tasks.prefix(3)) { task in
                    HStack(spacing: 8) {
                        Button {
                            viewModel.toggleTask(task)
                        } label: {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? Color.channelClay : Color.islandsBlue.opacity(0.5))
                        }
                        .buttonStyle(.plain)

                        Text(task.title)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .strikethrough(task.isCompleted)
                            .foregroundColor(task.isCompleted ? .secondary : .primary)

                        Spacer()
                    }
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
                mintBackground
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.07), radius: 8, x: 0, y: 4)
    }
}
