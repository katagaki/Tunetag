//
//  FileType.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/10.
//

import Foundation
import SwiftUI

enum FileType: String, Codable {
    case mp3
    case zip

    func iconName() -> Image {
        switch self {
        case .mp3:
            return Image("File.MP3")
        case .zip:
            return Image("File.ZIP")
        }
    }
}
