//
//  LargeButtonLabel.swift
//  Tunetag
//

import SwiftUI

struct LargeButtonLabel: View {

    var iconName: String?
    var text: String

    init(iconName: String? = nil, text: String) {
        self.iconName = iconName
        self.text = text
    }

    var body: some View {
        HStack(alignment: .center, spacing: 4.0) {
            if let iconName = iconName {
                Image(systemName: iconName)
            }
            Text(NSLocalizedString(text, comment: ""))
                .padding([.top, .bottom], 8.0)
        }
        .padding([.leading, .trailing], 10.0)
    }
}
