//
//  LargeButtonLabel.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import SwiftUI

struct LargeButtonLabel: View {

    @State var iconName: String?
    @State var text: String

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
