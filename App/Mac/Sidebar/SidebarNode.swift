//
//  SidebarNode.swift
//  Tunetag
//

import Foundation

@MainActor
final class SidebarNode {

    enum Kind: Sendable {
        case folder(URL)
        case files([URL])
    }

    let kind: Kind
    let isRoot: Bool

    /// The subfolders, or nil until they've been listed.
    private(set) var children: [SidebarNode]?
    private var childrenTask: Task<Void, Never>?

    init(kind: Kind, isRoot: Bool = false) {
        self.kind = kind
        self.isRoot = isRoot
        if case .files = kind {
            children = []
        }
    }

    var title: String {
        switch kind {
        case .folder(let url): FileManager.default.displayName(atPath: url.path(percentEncoded: false))
        case .files: MacText.string("Sidebar.Files")
        }
    }

    var symbolName: String {
        switch kind {
        case .folder: "folder"
        case .files: "doc.on.doc"
        }
    }

    /// Lists the subfolders in the background, once.
    func loadChildren() async {
        if let childrenTask {
            await childrenTask.value
            return
        }
        guard children == nil, case .folder(let url) = kind else { return }
        let task = Task {
            let urls = await Task.detached(priority: .userInitiated) {
                AudioFileLister.subfolderURLs(of: url)
            }.value
            children = urls.map { SidebarNode(kind: .folder($0)) }
        }
        childrenTask = task
        await task.value
    }

    /// The audio files the browser shows for a node. This lists folders, so run it off the main thread.
    nonisolated static func fileURLs(of kind: Kind, includingSubfolders: Bool) -> [URL] {
        switch kind {
        case .folder(let url):
            return AudioFileLister.audioFileURLs(in: url, includingSubfolders: includingSubfolders)
        case .files(let urls):
            return urls.flatMap { url in
                url.isDirectory
                    ? AudioFileLister.audioFileURLs(in: url, includingSubfolders: includingSubfolders)
                    : [url]
            }
        }
    }
}
