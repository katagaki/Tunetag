//
//  AudioFileLister.swift
//  Tunetag
//

import Foundation
import Prelude

/// Lists folders and audio files. Listing can take a while on large folders,
/// so callers run it off the main thread; it stops early once its task is cancelled.
enum AudioFileLister {

    static let supportedExtensions = Set(TagLibFile.supportedExtensions())

    static func isSupportedAudioFile(_ url: URL) -> Bool {
        !url.isDirectory && supportedExtensions.contains(url.pathExtension.lowercased())
    }

    static func audioFileURLs(in folder: URL, includingSubfolders: Bool = false) -> [URL] {
        let urls = includingSubfolders ? descendants(of: folder) : contents(of: folder)
        return urls
            .filter(isSupportedAudioFile)
            .map { ($0, ($0.path(percentEncoded: false) as NSString).pathComponents) }
            .sorted { pathOrder($0.1, $1.1) == .orderedAscending }
            .map(\.0)
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

    /// Orders paths, given as their components, by folder one component at a time and
    /// then by file name, so a folder's own files come before the files in its subfolders.
    static func pathOrder(_ lhsComponents: [String], _ rhsComponents: [String]) -> ComparisonResult {
        let lhsFolders = lhsComponents.dropLast()
        let rhsFolders = rhsComponents.dropLast()
        for (lhsFolder, rhsFolder) in zip(lhsFolders, rhsFolders) {
            let order = lhsFolder.localizedStandardCompare(rhsFolder)
            if order != .orderedSame {
                return order
            }
        }
        if lhsFolders.count != rhsFolders.count {
            return lhsFolders.count < rhsFolders.count ? .orderedAscending : .orderedDescending
        }
        return (lhsComponents.last ?? "").localizedStandardCompare(rhsComponents.last ?? "")
    }

    private static func contents(of folder: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
            options: [.skipsHiddenFiles]
        )) ?? []
    }

    private static func descendants(of folder: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }
        var urls: [URL] = []
        while let url = enumerator.nextObject() as? URL {
            guard !Task.isCancelled else { return [] }
            urls.append(url)
        }
        return urls
    }
}
