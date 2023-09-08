//
//  ViewPath.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import Foundation

enum ViewPath: Hashable {
    case fileBrowser(directory: FSDirectory)
    case fileInfo(file: FSFile)
    case batchFileInfo(files: [FSFile])
}
