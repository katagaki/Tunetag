//
//  TagEditorView+Saving.swift
//  Tunetag
//

import Prelude
import SwiftUI

extension TagEditorView {

    func readAllTagData() async {
        await MainActor.run {
            withAnimation(.snappy.speed(2)) {
                isReadingTags = true
            }
        }
        let filesToRead = files
        let tagCombined = await Task.detached(priority: .userInitiated) {
            TagSnapshot.read(paths: filesToRead.map(\.path))
        }.value

        await MainActor.run {
            tagData = tagCombined.map { Tag(from: $0) } ?? Tag()
            loadedTagData = tagData
            isAlbumArtRemoved = false
            withAnimation(.snappy.speed(2)) {
                isReadingTags = false
            }
        }
    }

    func saveAllTagData() async -> Bool {
        await MainActor.run {
            withAnimation(.snappy.speed(2)) {
                savedFileCount = 0
                totalFileCount = files.count
            }
        }
        let filesToSave = files
        let tagSnapshot = tagData
        let albumArtRemoved = isAlbumArtRemoved

        let maxConcurrentSaves = 4
        return await withTaskGroup(of: Bool.self) { group in
            var iterator = filesToSave.makeIterator()
            var allSaved = true

            func addNext() -> Bool {
                guard let file = iterator.next() else { return false }
                group.addTask(priority: .userInitiated) {
                    return await TagFileIO.save(tagSnapshot, to: file, albumArtRemoved: albumArtRemoved)
                }
                return true
            }

            var startedSaves = 0
            while startedSaves < maxConcurrentSaves && addNext() {
                startedSaves += 1
            }

            while let saved = await group.next() {
                allSaved = allSaved && saved
                await MainActor.run {
                    withAnimation(.snappy.speed(2)) {
                        if saved {
                            savedFileCount += 1
                        }
                    }
                }
                _ = addNext()
            }
            return allSaved
        }
    }

    func removeAllTagsFromFiles() async {
        changeSaveState(to: .saving)
        var allRemoved = true
        for file in files {
            let removed = await TagFileIO.removeAllTags(from: file)
            allRemoved = allRemoved && removed
        }
        await readAllTagData()
        changeSaveState(to: allRemoved ? .saved : .notSaved)
        showsRemoveTagsError = !allRemoved
    }
}
