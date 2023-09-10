//
//  FileBrowserNoFilesTip.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import Foundation
import TipKit

@available(iOS 17.0, *)
struct FileBrowserNoFilesTip: Tip {
    var title: Text {
        Text("FileBrowser.Tip.NoFiles.Title")
    }
    var message: Text? {
        Text("FileBrowser.Tip.NoFiles.Text")
    }
    var image: Image? {
        Image(systemName: "questionmark.folder.fill")
    }
}
