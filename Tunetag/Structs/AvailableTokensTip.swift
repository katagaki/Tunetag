//
//  AvailableTokensTip.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import Foundation
import TipKit

struct AvailableTokensTip: Tip {
    var title: Text {
        Text("FileInfo.Tip.Tokens.Title")
    }
    var message: Text? {
        Text("FileInfo.Tip.Tokens.Text")
    }
    var image: Image? {
        Image(systemName: "info.circle.fill")
    }
}
