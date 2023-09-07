//
//  ListDetailRow.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import SwiftUI

struct ListDetailRow: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(NSLocalizedString(title, comment: ""))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(NSLocalizedString(subtitle, comment: ""))
                .font(.body)
        }
        .padding([.top, .bottom], 2.0)
    }
}
