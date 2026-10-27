//
//  Preferences.swift
//  Tunetag
//

import Foundation

enum Preferences {
    static let startWithPreviousSelectionKey = "General.StartWithPreviousSelection"
    static let browserViewModeKey = "Browser.ViewMode"

    static var startsWithPreviousSelection: Bool {
        UserDefaults.standard.bool(forKey: startWithPreviousSelectionKey)
    }
}
