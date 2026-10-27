//
//  ExtendedTagsSection.swift
//  Tunetag
//

import Prelude
import SwiftUI

/// The file's other tags, edited as raw properties and saved along with the standard fields.
struct ExtendedTagsSection: View {

    @Bindable var model: TagInspectorModel
    @State private var isAddingField = false

    var body: some View {
        Section(MacText.shared("TagEditor.ExtendedTags")) {
            if model.extendedFields.isEmpty {
                Text(MacText.shared("ExtendedTags.Empty"))
                    .foregroundStyle(.secondary)
            }
            ForEach($model.extendedFields) { $field in
                ExtendedTagFieldRow(field: $field) {
                    model.removeExtendedField(field)
                }
            }
            Button(MacText.shared("ExtendedTags.AddField"), systemImage: "plus") {
                isAddingField = true
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $isAddingField, arrowEdge: .bottom) {
                AddExtendedTagPopover { key, value in
                    model.addExtendedField(key: key, value: value)
                }
            }
        }
    }
}

private struct ExtendedTagFieldRow: View {

    @Binding var field: ExtendedTagField
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            TextField(TagKey.displayName(for: field.key), text: $field.value, prompt: Text(verbatim: ""),
                      axis: .vertical)
                .lineLimit(1...8)
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help(MacText.string("Inspector.RemoveField"))
            .accessibilityLabel(MacText.string("Inspector.RemoveField"))
        }
        .help(field.key)
    }
}

private struct AddExtendedTagPopover: View {

    let onAdd: (_ key: String, _ value: String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var value = ""

    private var key: String {
        TagKey.key(forDisplayName: name)
    }

    /// Fields the standard editor covers are left to it, so the two don't overwrite each other.
    private var canAdd: Bool {
        !key.isEmpty && !TagKey.editorKeys.contains(key)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(MacText.shared("ExtendedTags.AddField"))
                .font(.headline)
            TextField(MacText.shared("ExtendedTags.FieldName"), text: $name)
            TextField(MacText.shared("ExtendedTags.Value"), text: $value)
            HStack {
                Spacer()
                Button(MacText.shared("Shared.Cancel"), role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button(MacText.shared("Shared.Add")) {
                    onAdd(key, value)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canAdd)
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .frame(width: 280)
    }
}
