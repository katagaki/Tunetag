//
//  SessionStore.swift
//  Tunetag
//

import Foundation

/// Remembers the last files or folder opened, as security-scoped bookmarks so
/// the sandbox lets the app back in on the next launch.
enum SessionStore {

    private static let bookmarksKey = "Session.LastOpenedBookmarks"

    static func remember(_ urls: [URL]) {
        let bookmarks = urls.compactMap { url in
            try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        }
        UserDefaults.standard.set(bookmarks, forKey: bookmarksKey)
    }

    static func restore() -> [URL] {
        let bookmarks = UserDefaults.standard.array(forKey: bookmarksKey) as? [Data] ?? []
        return bookmarks.compactMap { bookmark in
            var isStale = false
            guard let url = try? URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ), FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
                return nil
            }
            return url
        }
    }
}
