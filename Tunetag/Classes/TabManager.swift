//
//  TabManager.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import Foundation

class TabManager: ObservableObject {
    @Published var selectedTab: TabType = .batchEdit
    @Published var previouslySelectedTab: TabType = .batchEdit
}
