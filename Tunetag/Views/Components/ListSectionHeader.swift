//
//  ListSectionHeader.swift
//  Tunetag
//

import SwiftUI

struct ListSectionHeader: View {

    var text: String

    init(text: String) {
        self.text = text
    }

    var body: some View {
        Text(LocalizedStringKey(text))
            .font(.body)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .textCase(nil)
            .lineLimit(1)
            .truncationMode(.middle)
            .allowsTightening(true)
    }
}
