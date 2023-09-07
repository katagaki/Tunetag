//
//  ListHintOverlay.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import SwiftUI

struct ListHintOverlay: View {
    var image: String
    var text: String

    var body: some View {
        VStack(alignment: .center, spacing: 4.0) {
            Image(systemName: image)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 32.0, weight: .regular))
                .foregroundColor(.secondary)
            Text(NSLocalizedString(text, comment: ""))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16.0)
    }
}
