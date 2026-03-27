//
//  MoreView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import SwiftUI

struct MoreView: View {

    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        NavigationStack(path: $navigationManager.moreTabPath) {
            List {
                Section {
                    Link(destination: URL(string: "https://github.com/katagaki/Tunetag")!) {
                        HStack {
                            Text(String(localized: "More.GitHub"))
                            Spacer()
                            Text("katagaki/Tunetag")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                    NavigationLink("More.Attributions", value: ViewPath.moreAttributions)
                }
            }
            .navigationTitle("ViewTitle.More")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .moreAttributions: MoreLicensesView()
                default:
                    Color.clear
                }
            })
        }
    }
}
