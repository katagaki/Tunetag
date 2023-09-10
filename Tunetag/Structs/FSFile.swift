//
//  FSFile.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct FSFile: FilesystemObject, Codable, Transferable {

    var name: String
    var path: String
    var filetype: FileType

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: FSFile.self, contentType: .file)
        ProxyRepresentation(exporting: \.name)
    }
}

extension UTType {
    static var file: UTType { UTType(exportedAs: "com.tsubuzaki.Tunetag.MP3File") }
}
