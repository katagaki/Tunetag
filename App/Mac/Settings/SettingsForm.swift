//
//  SettingsForm.swift
//  Tunetag
//

import SwiftUI

/// A settings pane laid out like Safari's: labels right-aligned in a column,
/// controls beside them. A plain stack rather than a `Form`, which scrolls and
/// so can't report the height the window needs to fit it.
struct SettingsForm<Content: View>: View {

    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .labeledContentStyle(SettingsColumnStyle())
        .toggleStyle(.checkbox)
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .frame(width: 600, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct SettingsColumnStyle: LabeledContentStyle {

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            configuration.label
                .multilineTextAlignment(.trailing)
                .frame(width: 160, alignment: .trailing)
            configuration.content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SettingsNote: View {

    let text: String

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 360, alignment: .leading)
    }
}
