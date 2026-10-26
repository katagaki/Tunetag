//
//  AvailableTokensTip.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import Foundation
import TipKit

@available(iOS 17.0, *)
struct AvailableTokensTip: Tip {
    var title: Text {
        Text("TagEditor.Tip.Tokens.Title")
    }
    var message: Text? {
        Text("TagEditor.Tip.Tokens.Text")
    }
    var image: Image? {
        Image(systemName: "info.circle.fill")
    }
}
