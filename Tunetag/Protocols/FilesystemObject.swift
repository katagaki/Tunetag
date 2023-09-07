//
//  FilesystemObject.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import Foundation

protocol FilesystemObject: Hashable {
    var name: String { get set }
    var path: String { get set }
}
