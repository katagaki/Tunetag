//
//  MainTabView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import StoreKit
import SwiftUI
import TipKit

struct MainTabView: View {

    @Environment(\.requestReview) var requestReview
    @EnvironmentObject var tabManager: TabManager
    @EnvironmentObject var navigationManager: NavigationManager
    @AppStorage(wrappedValue: false, "ReviewPrompted", store: .standard) var hasReviewBeenPrompted: Bool

    var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            FileBrowserView()
                .tabItem {
                    Label("TabTitle.Files", image: "Tab.FileBrowser")
                }
                .toolbarBackground(.hidden, for: .tabBar)
                .safeAreaInset(edge: .bottom) {
                    DropZone()
                }
                .tag(TabType.fileManager)
            BatchEditView()
                .tabItem {
                    Label("TabTitle.BatchEditor", image: "Tab.BatchEditor")
                }
                .tag(TabType.batchEdit)
            MoreView()
                .tabItem {
                    Label("TabTitle.More", systemImage: "ellipsis")
                }
                .tag(TabType.more)
        }
        .task {
            if #available(iOS 17.0, *) {
                try? Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
            }
            if !hasReviewBeenPrompted {
                requestReview()
                hasReviewBeenPrompted = true
            }
        }
        .onReceive(tabManager.$selectedTab, perform: { newValue in
            if newValue == tabManager.previouslySelectedTab {
                navigationManager.popToRoot(for: newValue)
            }
            tabManager.previouslySelectedTab = newValue
        })
    }
}
