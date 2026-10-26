//
//  AvailableTokenRow.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import SwiftUI

struct AvailableTokenRow: View {

    var tokenName: String
    var tokenDescription: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(verbatim: "%\(tokenName)%")
                .textSelection(.enabled)
                .font(.body.monospaced())
                .bold()
            Text(NSLocalizedString(tokenDescription, comment: ""))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct AvailableTokensPopover: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12.0) {
                ListSectionHeader(text: "TagEditor.Tokens.Title")
                AvailableTokenRow(tokenName: "FILENAME", tokenDescription: "TagEditor.Tokens.Filename.Description")
                Divider()
                AvailableTokenRow(tokenName: "SPLITFRONT", tokenDescription: "TagEditor.Tokens.SplitFront.Description")
                Divider()
                AvailableTokenRow(tokenName: "SPLITBACK", tokenDescription: "TagEditor.Tokens.SplitBack.Description")
            }
            .padding()
        }
        .frame(width: 300.0, height: 280.0)
    }
}
