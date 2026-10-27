//
//  SidebarNode.swift
//  Tunetag
//

import Foundation

final class SidebarNode {

    enum Kind {
        case folder(URL)
        case files([URL])
    }

    let kind: Kind
    let isRoot: Bool

    init(kind: Kind, isRoot: Bool = false) {
        self.kind = kind
        self.isRoot = isRoot
    }

    var title: String {
        switch kind {
        case .folder(let url): FileManager.default.displayName(atPath: url.path(percentEncoded: false))
        case .files: MacText.shared("ViewTitle.Files")
        }
    }

    var symbolName: String {
        switch kind {
        case .folder: "folder"
        case .files: "doc.on.doc"
        }
    }

    lazy var children: [SidebarNode] = {
        guard case .folder(let url) = kind else { return [] }
        return AudioFileLister.subfolderURLs(of: url).map { SidebarNode(kind: .folder($0)) }
    }()

    var fileURLs: [URL] {
        switch kind {
        case .folder(let url): AudioFileLister.audioFileURLs(in: url)
        case .files(let urls): urls
        }
    }
}
