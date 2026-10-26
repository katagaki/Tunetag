//
//  ListInputRow.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import Prelude
import SwiftUI

struct ListInputRow: View {

    var title: String
    @Binding var value: String?
    var field: FocusedField
    var focusedField: FocusState<FocusedField?>.Binding
    var isBatchEditing: Bool = false
    var isMultiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            TagFieldLabel(title: title)
                .accessibilityHidden(true)
            TextField(placeholder,
                      text: Binding(get: { value ?? "" }, set: { value = $0 }),
                      axis: isMultiline ? .vertical : .horizontal)
            .lineLimit(isMultiline ? 1...8 : 1...1)
            .focused(focusedField, equals: field)
            .submitLabel(.next)
            .onSubmit {
                focusedField.wrappedValue = field.next
            }
            .accessibilityLabel(Text(NSLocalizedString(title, comment: "")))
        }
    }

    var placeholder: String {
        isBatchEditing && value == nil ? String(localized: "BatchEdit.Keep") : ""
    }
}

struct ListNumberPairRow: View {

    var title: String
    @Binding var number: String?
    @Binding var total: String?
    var numberField: FocusedField
    var totalField: FocusedField
    var focusedField: FocusState<FocusedField?>.Binding
    var isBatchEditing: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            TagFieldLabel(title: title)
                .accessibilityHidden(true)
            HStack(alignment: .firstTextBaseline, spacing: 8.0) {
                TextField(placeholder(for: number, fallback: ""),
                          text: Binding(get: { number ?? "" }, set: { number = $0 }))
                .focused(focusedField, equals: numberField)
                .accessibilityLabel(Text(NSLocalizedString(title, comment: "")))
                .accessibilityValue(accessibilityValue(for: number))
                Text(verbatim: "/")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
                TextField(placeholder(for: total, fallback: String(localized: "Tag.Total")),
                          text: Binding(get: { total ?? "" }, set: { total = $0 }))
                .focused(focusedField, equals: totalField)
                .accessibilityLabel(Text("\(NSLocalizedString(title, comment: "")), \(String(localized: "Tag.Total"))"))
                .accessibilityValue(accessibilityValue(for: total))
            }
        }
        .keyboardType(.numberPad)
    }

    /// The number fields are too narrow for "Don't Change", so mixed values show a dash instead.
    func placeholder(for value: String?, fallback: String) -> String {
        isBatchEditing && value == nil ? "—" : fallback
    }

    func accessibilityValue(for value: String?) -> Text {
        isBatchEditing && value == nil ? Text("BatchEdit.Keep") : Text(verbatim: value ?? "")
    }
}

struct ListTrackDiscRow: View {

    @Binding var tagData: Tag
    var focusedField: FocusState<FocusedField?>.Binding
    var isBatchEditing: Bool = false

    var body: some View {
        HStack(spacing: 12.0) {
            ListNumberPairRow(title: "Tag.Track", number: $tagData.track, total: $tagData.trackTotal,
                              numberField: .trackNumber, totalField: .trackTotal,
                              focusedField: focusedField, isBatchEditing: isBatchEditing)
            Divider()
            ListNumberPairRow(title: "Tag.Disc", number: $tagData.discNumber, total: $tagData.discTotal,
                              numberField: .discNumber, totalField: .discTotal,
                              focusedField: focusedField, isBatchEditing: isBatchEditing)
        }
    }
}

struct ListCompilationRow: View {

    @Binding var isCompilation: Bool?
    var isBatchEditing: Bool = false

    var body: some View {
        if isBatchEditing {
            Picker(selection: $isCompilation) {
                Text("BatchEdit.Keep").tag(Bool?.none)
                Text("Shared.Yes").tag(Bool?.some(true))
                Text("Shared.No").tag(Bool?.some(false))
            } label: {
                Text("Tag.Compilation")
            }
            .pickerStyle(.menu)
        } else {
            Toggle(isOn: Binding(get: { isCompilation ?? false }, set: { isCompilation = $0 })) {
                Text("Tag.Compilation")
            }
        }
    }
}

struct TagFieldLabel: View {

    var title: String

    var body: some View {
        Text(NSLocalizedString(title, comment: ""))
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}
