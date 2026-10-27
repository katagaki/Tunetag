//
//  TagInspectorModel.swift
//  Tunetag
//

import Foundation
import Observation
import Prelude

/// Follows the browser's selection, reading the selected files' tags once the
/// selection has settled, and writing edits back to all of them.
@MainActor @Observable
final class TagInspectorModel {

    private static let selectionDebounce: Duration = .milliseconds(250)
    private static let maxConcurrentSaves = 4

    private(set) var files: [FSFile] = []
    private(set) var loadedFiles: [FSFile] = []
    private(set) var loadedTag = Tag()
    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var savedFileCount = 0
    private(set) var loadedExtendedFields: [ExtendedTagField] = []
    private(set) var unsupportedKeys: [String] = []
    var isShowingSaveError = false
    var isShowingRemoveTagsError = false
    var isShowingUnsupportedKeys = false
    var tag = Tag() {
        didSet { notifyDirtyChangeIfNeeded() }
    }
    var isAlbumArtRemoved = false {
        didSet { notifyDirtyChangeIfNeeded() }
    }
    /// The file's tags that the standard fields don't cover, read only when a single file is selected.
    var extendedFields: [ExtendedTagField] = [] {
        didSet { notifyDirtyChangeIfNeeded() }
    }
    var showsExtendedTags = Preferences.showsExtendedTags {
        didSet {
            // Hidden edits would be saved without being seen, so drop them
            if !showsExtendedTags {
                extendedFields = loadedExtendedFields
            }
        }
    }

    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var wasDirty = false
    @ObservationIgnored var onSave: (([FSFile]) -> Void)?
    @ObservationIgnored var onDirtyChange: ((Bool) -> Void)?

    var isBatchEditing: Bool {
        loadedFiles.count > 1
    }

    var isDirty: Bool {
        !loadedFiles.isEmpty && (tag != loadedTag || isAlbumArtRemoved || extendedFields != loadedExtendedFields)
    }

    var canEditExtendedTags: Bool {
        showsExtendedTags && loadedFiles.count == 1
    }

    var canSave: Bool {
        isDirty && !isLoading && !isSaving && tag.hasValidNumbers && loadedFiles == files
    }

    func select(_ newFiles: [FSFile]) {
        guard newFiles != files else { return }
        loadTask?.cancel()
        files = newFiles
        guard !newFiles.isEmpty else {
            isLoading = false
            show(Tag(), extendedFields: [], for: [])
            return
        }
        isLoading = true
        loadTask = Task { [weak self] in
            try? await Task.sleep(for: Self.selectionDebounce)
            guard !Task.isCancelled else { return }
            await self?.load(newFiles)
        }
    }

    func save() {
        guard canSave else { return }
        let savingFiles = files
        let savingTag = tag
        let albumArtRemoved = isAlbumArtRemoved
        let savingProperties = extendedFields != loadedExtendedFields ? extendedPropertyChanges() : [:]
        isSaving = true
        savedFileCount = 0
        Task {
            let allSaved = await withTaskGroup(of: Bool.self) { group in
                var iterator = savingFiles.makeIterator()
                var allSaved = true
                func addNext() -> Bool {
                    guard let file = iterator.next() else { return false }
                    group.addTask {
                        await TagFileIO.save(savingTag, to: file, albumArtRemoved: albumArtRemoved,
                                             properties: savingProperties)
                    }
                    return true
                }
                var startedSaves = 0
                while startedSaves < Self.maxConcurrentSaves && addNext() {
                    startedSaves += 1
                }
                while let saved = await group.next() {
                    allSaved = allSaved && saved
                    savedFileCount += 1
                    _ = addNext()
                }
                return allSaved
            }
            await finishWriting(savingFiles, succeeded: allSaved) { self.isShowingSaveError = true }
            if allSaved && loadedFiles == savingFiles {
                reportUnsupportedKeys(in: savingProperties)
            }
        }
    }

    func addExtendedField(key: String, value: String) {
        extendedFields.append(ExtendedTagField(key: key, value: value))
    }

    func removeExtendedField(_ field: ExtendedTagField) {
        extendedFields.removeAll { $0.id == field.id }
    }

    /// Every extended property's new values, where an empty array removes a property that was deleted.
    private func extendedPropertyChanges() -> [String: [String]] {
        var changes: [String: [String]] = [:]
        for field in loadedExtendedFields {
            changes[field.key] = []
        }
        for field in extendedFields where !field.value.isEmpty {
            changes[field.key, default: []].append(field.value)
        }
        return changes
    }

    /// Lists the saved properties that didn't come back when the file was read again.
    private func reportUnsupportedKeys(in properties: [String: [String]]) {
        let loadedKeys = Set(loadedExtendedFields.map(\.key))
        let missingKeys = properties.filter { !$0.value.isEmpty && !loadedKeys.contains($0.key) }.keys
        guard !missingKeys.isEmpty else { return }
        unsupportedKeys = missingKeys.map { TagKey.displayName(for: $0) }.sorted()
        isShowingUnsupportedKeys = true
    }

    func removeAllTags() {
        guard !loadedFiles.isEmpty, !isLoading, !isSaving else { return }
        let removingFiles = loadedFiles
        isSaving = true
        savedFileCount = 0
        Task {
            var allRemoved = true
            for file in removingFiles {
                let removed = await TagFileIO.removeAllTags(from: file)
                allRemoved = allRemoved && removed
                savedFileCount += 1
            }
            await finishWriting(removingFiles, succeeded: allRemoved) { self.isShowingRemoveTagsError = true }
        }
    }

    /// Re-reads the files that were written, so tokens show as the values they became.
    private func finishWriting(_ writtenFiles: [FSFile], succeeded: Bool, onFailure: () -> Void) async {
        onSave?(writtenFiles)
        if writtenFiles == files {
            await load(writtenFiles)
        }
        isSaving = false
        if !succeeded {
            onFailure()
        }
    }

    private func load(_ filesToLoad: [FSFile]) async {
        let paths = filesToLoad.map(\.path)
        let (snapshot, properties) = await Task.detached(priority: .userInitiated) {
            () -> (TagSnapshot?, [String: [String]]) in
            guard paths.count == 1 else { return (TagSnapshot.read(paths: paths), [:]) }
            guard let file = TagLibFile(path: paths[0]) else { return (nil, [:]) }
            return (TagSnapshot(file), file.properties)
        }.value
        guard !Task.isCancelled, filesToLoad == files else { return }
        show(snapshot.map { Tag(from: $0) } ?? Tag(), extendedFields: Self.extendedFields(from: properties),
             for: filesToLoad)
        isLoading = false
    }

    private static func extendedFields(from properties: [String: [String]]) -> [ExtendedTagField] {
        let sortedKeys = properties.keys.filter { !TagKey.editorKeys.contains($0) }.sorted {
            TagKey.displayName(for: $0).localizedStandardCompare(TagKey.displayName(for: $1)) == .orderedAscending
        }
        return sortedKeys.flatMap { key in
            (properties[key] ?? []).map { ExtendedTagField(key: key, value: $0) }
        }
    }

    private func show(_ newTag: Tag, extendedFields newExtendedFields: [ExtendedTagField], for newFiles: [FSFile]) {
        loadedFiles = newFiles
        loadedTag = newTag
        tag = newTag
        isAlbumArtRemoved = false
        loadedExtendedFields = newExtendedFields
        extendedFields = newExtendedFields
    }

    private func notifyDirtyChangeIfNeeded() {
        guard isDirty != wasDirty else { return }
        wasDirty = isDirty
        onDirtyChange?(isDirty)
    }
}

/// One value of a raw tag property. Properties with several values have a field for each.
struct ExtendedTagField: Identifiable, Equatable {
    let id = UUID()
    var key: String
    var value: String
}
