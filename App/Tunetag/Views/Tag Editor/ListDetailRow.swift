//
//  ListDetailRow.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import SwiftUI

struct ListDetailRow: View {

    var title: String
    var value: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            TagFieldLabel(title: title)
            Group {
                if let value {
                    Text(value)
                        .textSelection(.enabled)
                } else {
                    Text(verbatim: "-")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}
