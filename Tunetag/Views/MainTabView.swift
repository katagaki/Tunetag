//
//  MainTabView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import SwiftUI

struct MainTabView: View {

    @EnvironmentObject var tabManager: TabManager
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            FileBrowserView()
                .tabItem {
                    Label("TabTitle.Files", systemImage: "folder.fill")
                }
                .tag(TabType.browser)
            BatchEditView()
                .tabItem {
                    Label("TabTitle.BatchEdit", systemImage: "pencil.line")
                }
                .tag(TabType.files)
            MoreView()
                .tabItem {
                    Label("TabTitle.More", systemImage: "ellipsis")
                }
                .tag(TabType.more)
        }
        .onReceive(tabManager.$selectedTab, perform: { newValue in
            if newValue == tabManager.previouslySelectedTab {
                navigationManager.popToRoot(for: newValue)
            }
            tabManager.previouslySelectedTab = newValue
        })
    }
}
