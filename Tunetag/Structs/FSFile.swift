//
//  FSFile.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct FSFile: Hashable, Codable, Identifiable, Transferable {

    var name: String
    var path: String
    var isArbitrarilyLoadedFromDragAndDrop: Bool = false

    var id: String {
        return path
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: FSFile.self, contentType: .audio)
        ProxyRepresentation(exporting: \.name)
    }
}
