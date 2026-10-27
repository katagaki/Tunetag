//
//  AudioFileLister.swift
//  Tunetag
//

import Foundation
import Prelude

enum AudioFileLister {

    static let supportedExtensions = Set(TagLibFile.supportedExtensions())

    static func isSupportedAudioFile(_ url: URL) -> Bool {
        !url.isDirectory && supportedExtensions.contains(url.pathExtension.lowercased())
    }

    static func audioFileURLs(in folder: URL) -> [URL] {
        contents(of: folder)
            .filter(isSupportedAudioFile)
            .sorted(using: KeyPathComparator(\.lastPathComponent, comparator: .localizedStandard))
    }

    static func subfolderURLs(of folder: URL) -> [URL] {
        contents(of: folder)
            .filter { url in
                let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
                return values?.isDirectory == true && values?.isPackage != true
            }
            .sorted(using: KeyPathComparator(\.lastPathComponent, comparator: .localizedStandard))
    }

    static func file(for url: URL) -> FSFile {
        FSFile(name: url.lastPathComponent, path: url.path(percentEncoded: false))
    }

    private static func contents(of folder: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
            options: [.skipsHiddenFiles]
        )) ?? []
    }
}
