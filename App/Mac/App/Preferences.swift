//
//  Preferences.swift
//  Tunetag
//

import Foundation

enum Preferences {
    static let startWithPreviousSelectionKey = "General.StartWithPreviousSelection"
    static let browserViewModeKey = "Browser.ViewMode"
    static let includeSubfoldersKey = "Browser.IncludeSubfolders"

    static var startsWithPreviousSelection: Bool {
        UserDefaults.standard.bool(forKey: startWithPreviousSelectionKey)
    }

    /// Whether a folder shows the audio files in its subfolders too.
    static var includesSubfolders: Bool {
        get { UserDefaults.standard.bool(forKey: includeSubfoldersKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: includeSubfoldersKey)
            NotificationCenter.default.post(name: .includeSubfoldersDidChange, object: nil)
        }
    }
}

extension Notification.Name {
    static let includeSubfoldersDidChange = Notification.Name("IncludeSubfoldersDidChange")
}
