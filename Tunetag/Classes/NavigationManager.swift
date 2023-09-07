//
//  NavigationManager.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import Foundation

class NavigationManager: ObservableObject {

    @Published var browserTabPath: [ViewPath] = []

    func popToRoot(for tab: TabType) {
        switch tab {
        case .browser:
            browserTabPath.removeAll()
        case .files:
            break
        case .more:
            break
        }
    }

    func push(_ viewPath: ViewPath, for tab: TabType) {
        switch tab {
        case .browser:
            browserTabPath.append(viewPath)
        case .files:
            break
        case .more:
            break
        }
    }

}
