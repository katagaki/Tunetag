//
//  TagFieldRow.swift
//  Tunetag
//

import SwiftUI

/// A tag field. When batch editing, nil means the files disagree and saving keeps each file's own value.
struct TagFieldRow: View {

    let titleKey: String
    @Binding var value: String?
    let isBatch: Bool
    var isMultiline = false

    var body: some View {
        HStack(alignment: isMultiline ? .top : .firstTextBaseline, spacing: 6) {
            TextField(
                MacText.shared(titleKey),
                text: keepAwareBinding($value),
                prompt: Text(isBatch && value == nil ? MacText.shared("BatchEdit.Keep") : ""),
                axis: isMultiline ? .vertical : .horizontal
            )
            .lineLimit(isMultiline ? 1...8 : 1...1)
            if isBatch {
                DontChangeButton(value: $value)
            }
        }
    }
}

/// Puts a field back to keeping each file's own value, as the iOS keyboard bar does.
struct DontChangeButton: View {

    @Binding var value: String?

    var body: some View {
        Button {
            value = nil
        } label: {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .help(MacText.shared("BatchEdit.DontChange"))
        .accessibilityLabel(MacText.shared("BatchEdit.DontChange"))
        .opacity(value == nil ? 0 : 1)
        .disabled(value == nil)
    }
}

/// A number and its total, such as track 5 of 12.
struct NumberPairRow: View {

    let titleKey: String
    @Binding var number: String?
    @Binding var total: String?
    let isBatch: Bool

    var body: some View {
        LabeledContent(MacText.shared(titleKey)) {
            HStack(spacing: 6) {
                TextField(MacText.shared(titleKey), text: keepAwareBinding($number), prompt: prompt(for: number))
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                Text(verbatim: "/")
                    .foregroundStyle(.tertiary)
                TextField(MacText.shared("Tag.Total"), text: keepAwareBinding($total),
                          prompt: prompt(for: total, fallback: MacText.shared("Tag.Total")))
                    .labelsHidden()
                if isBatch {
                    DontChangeButton(value: $number)
                }
            }
        }
    }

    private func prompt(for value: String?, fallback: String = "") -> Text {
        Text(isBatch && value == nil ? MacText.shared("BatchEdit.Keep") : fallback)
    }
}

struct CompilationRow: View {

    @Binding var isCompilation: Bool?
    let isBatch: Bool

    var body: some View {
        if isBatch {
            Picker(MacText.shared("Tag.Compilation"), selection: $isCompilation) {
                Text(MacText.shared("BatchEdit.Keep")).tag(Bool?.none)
                Text(MacText.shared("Shared.Yes")).tag(Bool?.some(true))
                Text(MacText.shared("Shared.No")).tag(Bool?.some(false))
            }
        } else {
            Toggle(MacText.shared("Tag.Compilation"),
                   isOn: Binding(get: { isCompilation ?? false }, set: { isCompilation = $0 }))
        }
    }
}
