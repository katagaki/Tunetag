//
//  EditorSession.swift
//  Tunetag
//

import Foundation

/// What a window edits: a folder and everything under it, or a fixed set of files.
enum EditorSession {
    case folder(URL)
    case files([URL])

    /// One folder opens as a folder; anything else opens as files, taking the
    /// audio files directly inside any folders that were chosen alongside them.
    init?(urls: [URL]) {
        if urls.count == 1, let url = urls.first, url.isDirectory {
            self = .folder(url)
            return
        }
        let files = urls.flatMap { url in
            url.isDirectory
                ? AudioFileLister.audioFileURLs(in: url)
                : [url].filter(AudioFileLister.isSupportedAudioFile)
        }
        guard !files.isEmpty else { return nil }
        self = .files(files)
    }

    var openedURLs: [URL] {
        switch self {
        case .folder(let url): [url]
        case .files(let urls): urls
        }
    }

    var title: String {
        switch self {
        case .folder(let url):
            FileManager.default.displayName(atPath: url.path(percentEncoded: false))
        case .files(let urls):
            urls.count == 1
                ? urls[0].lastPathComponent
                : String(format: MacText.string("Window.FileCount"), urls.count)
        }
    }
}

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
    }
}
