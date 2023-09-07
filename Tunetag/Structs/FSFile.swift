//
//  FSFile.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import Foundation

struct FSFile: FilesystemObject {

    var name: String
    var path: String
    var filetype: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

}
