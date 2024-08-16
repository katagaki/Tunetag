//
//  TipSection.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/10.
//

import Komponents
import SwiftUI

struct TipSection: View {

    @State var title: String
    @State var message: String
    @State var image: Image
    @Binding var showsTip: Bool

    var body: some View {
        if showsTip {
            Section {
                HStack(alignment: .top, spacing: 8.0) {
                    image
                        .font(.largeTitle)
                        .foregroundStyle(Color("AccentColor"))
                    Text(NSLocalizedString(message, comment: ""))
                }
                .padding([.top, .bottom], 2.0)
            } header: {
                HStack {
                    ListSectionHeader(text: NSLocalizedString(title, comment: ""))
                    Spacer()
                    Button {
                        withAnimation {
                            showsTip = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }
}
