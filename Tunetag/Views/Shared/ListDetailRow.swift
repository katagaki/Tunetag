//
//  ListDetailRow.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import SwiftUI

struct ListDetailRow: View {
    var title: String
    var placeholder: String?
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(NSLocalizedString(title, comment: ""))
                .font(.caption)
                .foregroundStyle(.secondary)
            if let placeholder = placeholder {
                TextField(NSLocalizedString(placeholder, comment: ""),
                          text: $value)
                    .font(.body)
            } else {
                TextField(NSLocalizedString(title, comment: ""),
                          text: $value)
                .font(.body)
            }
        }
        .padding([.top, .bottom], 2.0)
    }
}
