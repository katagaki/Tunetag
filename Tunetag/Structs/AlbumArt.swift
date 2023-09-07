//
//  AlbumArt.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import Foundation
import SwiftUI

struct AlbumArt: Transferable {

    let image: UIImage?

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            if let uiImage = UIImage(data: data) {
                return AlbumArt(image: uiImage)
            } else {
                return AlbumArt(image: nil)
            }
        }
    }

}
