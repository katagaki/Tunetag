//
//  NavigationManager.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import Foundation

class NavigationManager: ObservableObject {

    @Published var browserTabPath: [ViewPath] = []
    @Published var batchEditTabPath: [ViewPath] = []
    @Published var moreTabPath: [ViewPath] = []

    func popToRoot(for tab: TabType) {
        switch tab {
        case .fileManager:
            browserTabPath.removeAll()
        case .batchEdit:
            batchEditTabPath.removeAll()
        case .more:
            moreTabPath.removeAll()
        }
    }

    func push(_ viewPath: ViewPath, for tab: TabType) {
        switch tab {
        case .fileManager:
            browserTabPath.append(viewPath)
        case .batchEdit:
            batchEditTabPath.append(viewPath)
        case .more:
            moreTabPath.append(viewPath)
        }
    }

}
