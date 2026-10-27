//
//  Preferences.swift
//  Tunetag
//

import Foundation

enum Preferences {
    static let startWithPreviousSelectionKey = "General.StartWithPreviousSelection"
    static let browserViewModeKey = "Browser.ViewMode"
    static let includeSubfoldersKey = "Browser.IncludeSubfolders"
    static let showExtendedTagsKey = "Inspector.ShowExtendedTags"

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

    /// Whether the inspector lists the file's other tags below the standard fields.
    static var showsExtendedTags: Bool {
        get { UserDefaults.standard.bool(forKey: showExtendedTagsKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: showExtendedTagsKey)
            NotificationCenter.default.post(name: .showExtendedTagsDidChange, object: nil)
        }
    }
}

extension Notification.Name {
    static let includeSubfoldersDidChange = Notification.Name("IncludeSubfoldersDidChange")
    static let showExtendedTagsDidChange = Notification.Name("ShowExtendedTagsDidChange")
}
