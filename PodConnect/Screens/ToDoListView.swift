//
//  ToDoListView.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 5/8/26.
//

import Foundation
import SwiftUI

struct ToDoListView: View {
    @ObservedObject var viewModel: ToDoViewModel
    @State private var newTaskTitle = ""

    
    

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("To-Do")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 18)
                .background(Color.islandsBlue)

                HStack(spacing: 10) {
                    TextField("New task", text: $newTaskTitle)
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        viewModel.addTask(title: newTaskTitle)
                        newTaskTitle = ""
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.channelClay)
                            .clipShape(Circle())
                    }
                }
                .padding()

                List {
                    ForEach(viewModel.tasks) { task in
                        HStack(spacing: 12) {
                            Button {
                                viewModel.toggleTask(task)
                            } label: {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(task.isCompleted ? Color.channelClay : Color.islandsBlue)
                            }
                            .buttonStyle(.plain)

                            Text(task.title)
                                .strikethrough(task.isCompleted)
                                .foregroundColor(task.isCompleted ? .secondary : .primary)

                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(Color(.secondarySystemGroupedBackground))
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteTask(viewModel.tasks[index])
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
