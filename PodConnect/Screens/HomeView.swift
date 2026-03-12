//
//  HomeView.swift
//  PodConnect
//
//  Created by Desiree Astabie on 3/11/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                Text("Search")
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            // Date
            Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal)

            // Feed Box
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Feed")
                    .font(.headline)
                    .bold()
                    .padding(.horizontal)
                    .padding(.top, 10)

                FeedRow(icon: "books.vertical.fill", label: "COMP 350", detail: "Today at 9:00 AM")
                Divider().padding(.horizontal)
                FeedRow(icon: "star", label: "Campus Event", detail: "Career Fair - 11 AM")
                Divider().padding(.horizontal)
                FeedRow(icon: "books.vertical.fill", label: "MATH 240", detail: "Today at 3:00 PM")
                    .padding(.bottom, 8)
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            // To Do and Messages Boxes
            HStack(spacing: 12) {

                // To Do Box
                VStack(alignment: .leading, spacing: 8) {
                    Text("To Do")
                        .font(.headline)
                        .bold()
                        .padding(.top, 10)
                        .padding(.leading)

                    FeedRow(icon: "checkmark.circle", label: "HW 3", detail: "Due tonight")
                    Divider()
                    FeedRow(icon: "checkmark.circle", label: "Study", detail: "Midterm Friday")
                        .padding(.bottom, 8)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(10)

                // Messages Box
                VStack(alignment: .leading, spacing: 8) {
                    Text("Messages")
                        .font(.headline)
                        .bold()
                        .padding(.top, 10)
                        .padding(.leading)

                    FeedRow(icon: "message", label: "Jack", detail: "coming to class?")
                    Divider()
                    FeedRow(icon: "message", label: "Jill", detail: "did u do the hw")
                        .padding(.bottom, 8)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
    }
}

struct FeedRow: View {
    let icon: String
    let label: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .bold()
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
}
