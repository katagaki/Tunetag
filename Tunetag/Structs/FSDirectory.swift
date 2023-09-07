//
//  FSDirectory.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import Foundation

struct FSDirectory: FilesystemObject {

    var name: String
    var path: String
    var files: [any FilesystemObject]

    static func == (lhs: FSDirectory, rhs: FSDirectory) -> Bool {
        lhs.path == rhs.path
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

}
