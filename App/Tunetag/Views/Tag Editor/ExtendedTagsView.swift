//
//  ExtendedTagsView.swift
//  Tunetag
//

import Prelude
import SwiftUI

struct ExtendedTagsView: View {

    struct Field: Identifiable, Equatable {
        let id = UUID()
        var key: String
        var value: String
    }

    var file: FSFile
    var onSave: () -> Void

    @State var fields: [Field] = []
    @State var loadedFields: [Field] = []
    @State var isLoading: Bool = true
    @State var isSaving: Bool = false
    @State var showsAddField: Bool = false
    @State var newFieldKey: String = ""
    @State var newFieldValue: String = ""
    @State var unsupportedKeys: [String] = []
    @State var showsUnsupportedKeys: Bool = false
    @State var showsSaveError: Bool = false

    var body: some View {
        List {
            ForEach($fields) { $field in
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(verbatim: TagKey.displayName(for: field.key))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityHidden(true)
                    TextField("ExtendedTags.Value", text: $field.value, axis: .vertical)
                        .lineLimit(1...8)
                        .accessibilityLabel(Text(verbatim: TagKey.displayName(for: field.key)))
                }
            }
            .onDelete { offsets in
                fields.remove(atOffsets: offsets)
            }
            .editorRowBackground()
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .controlSize(.large)
            } else if fields.isEmpty {
                ContentUnavailableView("ExtendedTags.Empty", systemImage: "tag.slash")
            }
        }
        .editorListBackground()
        .disabled(isLoading || isSaving)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("TagEditor.ExtendedTags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("ExtendedTags.AddField", systemImage: "plus") {
                    newFieldKey = ""
                    newFieldValue = ""
                    showsAddField = true
                }
                .disabled(isLoading || isSaving)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                Task { await save() }
            } label: {
                Group {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                            .padding([.top, .bottom], 8.0)
                    } else {
                        LargeButtonLabel(iconName: "square.and.arrow.down.fill", text: "Shared.Save")
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .modifier(SaveButtonStyleModifier())
            .frame(minHeight: 56.0)
            .padding([.leading, .trailing, .bottom])
            .disabled(isLoading || isSaving || fields == loadedFields)
        }
        .alert("ExtendedTags.AddField", isPresented: $showsAddField) {
            TextField("ExtendedTags.FieldName", text: $newFieldKey)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
            TextField("ExtendedTags.Value", text: $newFieldValue)
            Button("Shared.Cancel", role: .cancel) { }
            Button("Shared.Add") {
                addField()
            }
            .disabled(normalizedKey(newFieldKey).isEmpty)
        }
        .alert("ExtendedTags.Unsupported", isPresented: $showsUnsupportedKeys) {
            Button("Shared.OK", role: .cancel) { }
        } message: {
            Text(verbatim: unsupportedKeys.joined(separator: ", "))
        }
        .alert("TagEditor.SaveFailed.Message", isPresented: $showsSaveError) {
            Button("Shared.OK", role: .cancel) { }
        }
        .task {
            await load()
        }
    }

    func normalizedKey(_ key: String) -> String {
        TagKey.key(forDisplayName: key)
    }

    func addField() {
        let key = normalizedKey(newFieldKey)
        guard !key.isEmpty else { return }
        withAnimation {
            fields.append(Field(key: key, value: newFieldValue))
        }
    }

    func load() async {
        let path = file.path
        let properties = await Task.detached(priority: .userInitiated) {
            TagLibFile(path: path)?.properties ?? [:]
        }.value
        let sortedKeys = properties.keys.sorted {
            TagKey.displayName(for: $0).localizedStandardCompare(TagKey.displayName(for: $1)) == .orderedAscending
        }
        let loaded = sortedKeys.flatMap { key in
            (properties[key] ?? []).map { Field(key: key, value: $0) }
        }
        fields = loaded
        loadedFields = loaded
        isLoading = false
    }

    func save() async {
        isSaving = true
        let path = file.path
        let originalKeys = Set(loadedFields.map(\.key))
        var newValues: [String: [String]] = [:]
        for field in fields where !field.value.isEmpty {
            newValues[field.key, default: []].append(field.value)
        }
        let values = newValues
        let result = await Task.detached(priority: .userInitiated) { () -> (saved: Bool, unsupported: [String]) in
            guard let tagFile = TagLibFile(path: path) else { return (false, []) }
            for key in originalKeys where values[key] == nil {
                tagFile.setValues(nil, forProperty: key)
            }
            for (key, keyValues) in values {
                tagFile.setValues(keyValues, forProperty: key)
            }
            let saved = tagFile.save()
            return (saved, tagFile.unsupportedProperties)
        }.value

        await load()
        isSaving = false
        onSave()
        if !result.saved {
            showsSaveError = true
        } else if !result.unsupported.isEmpty {
            unsupportedKeys = result.unsupported
            showsUnsupportedKeys = true
        }
    }
}
