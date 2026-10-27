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
    var isShowingSaveError = false
    var isShowingRemoveTagsError = false
    var tag = Tag() {
        didSet { notifyDirtyChangeIfNeeded() }
    }
    var isAlbumArtRemoved = false {
        didSet { notifyDirtyChangeIfNeeded() }
    }

    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var wasDirty = false
    @ObservationIgnored var onSave: (([FSFile]) -> Void)?
    @ObservationIgnored var onDirtyChange: ((Bool) -> Void)?

    var isBatchEditing: Bool {
        loadedFiles.count > 1
    }

    var isDirty: Bool {
        !loadedFiles.isEmpty && (tag != loadedTag || isAlbumArtRemoved)
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
            show(Tag(), for: [])
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
        isSaving = true
        savedFileCount = 0
        Task {
            let allSaved = await withTaskGroup(of: Bool.self) { group in
                var iterator = savingFiles.makeIterator()
                var allSaved = true
                func addNext() -> Bool {
                    guard let file = iterator.next() else { return false }
                    group.addTask {
                        await TagFileIO.save(savingTag, to: file, albumArtRemoved: albumArtRemoved)
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
        }
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
        let snapshot = await Task.detached(priority: .userInitiated) {
            TagSnapshot.read(paths: paths)
        }.value
        guard !Task.isCancelled, filesToLoad == files else { return }
        show(snapshot.map { Tag(from: $0) } ?? Tag(), for: filesToLoad)
        isLoading = false
    }

    private func show(_ newTag: Tag, for newFiles: [FSFile]) {
        loadedFiles = newFiles
        loadedTag = newTag
        tag = newTag
        isAlbumArtRemoved = false
    }

    private func notifyDirtyChangeIfNeeded() {
        guard isDirty != wasDirty else { return }
        wasDirty = isDirty
        onDirtyChange?(isDirty)
    }
}
