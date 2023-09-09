//
//  ListDetailRow.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import SwiftUI

struct ListDetailRow: View {

    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(NSLocalizedString(title, comment: ""))
                .font(.caption)
                .foregroundStyle(.secondary)
            if value == "" {
                Text(verbatim: "-")
            } else {
                Text(value)
            }
        }
        .padding([.top, .bottom], 2.0)
    }
}
