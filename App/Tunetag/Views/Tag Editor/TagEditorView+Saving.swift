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
                    return await Self.saveTagData(to: file,
                                                  tag: tagSnapshot,
                                                  albumArtRemoved: albumArtRemoved)
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
            let removed = await Self.removeAllTags(from: file)
            allRemoved = allRemoved && removed
        }
        await readAllTagData()
        changeSaveState(to: allRemoved ? .saved : .notSaved)
        showsRemoveTagsError = !allRemoved
    }

    nonisolated static func saveTagData(to file: FSFile,
                                        tag: Tag,
                                        albumArtRemoved: Bool) async -> Bool {
        return await Task.detached(priority: .userInitiated) {
            // Each save opens its own file, since TagLib files can't be shared across tasks
            guard let tagFile = TagLibFile(path: file.path) else {
                debugPrint("Could not open file \(file.name) for saving")
                return false
            }
            let albumArt = tag.albumArt.flatMap { sanitizedImageData($0) }
            TagWriter.apply(tag, to: tagFile, albumArt: albumArt, albumArtRemoved: albumArtRemoved) {
                replaceTokens($0, file: file)
            }
            return tagFile.save()
        }.value
    }

    nonisolated static func removeAllTags(from file: FSFile) async -> Bool {
        return await Task.detached(priority: .userInitiated) {
            guard let tagFile = TagLibFile(path: file.path) else { return false }
            return tagFile.removeAllTags()
        }.value
    }

    nonisolated private static func sanitizedImageData(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        if let pngData = image.pngData() {
            return pngData
        }
        return image.jpegData(compressionQuality: 1.0)
    }

    nonisolated static func replaceTokens(_ original: String, file: FSFile) -> String {
        var newString = original
        let nameWithoutExtension = (file.name as NSString).deletingPathExtension
        let componentsDash = nameWithoutExtension
            .components(separatedBy: "-").map { string in
                string.trimmingCharacters(in: .whitespaces)
            }
        let tokens: [String: String] = [
            "fileName": nameWithoutExtension,
            "splitFront": componentsDash[0],
            "splitBack": componentsDash.count >= 2 ? componentsDash[1] : ""
        ]
        for (key, value) in tokens {
            newString = newString.replacingOccurrences(of: "%\(key)%", with: value, options: .caseInsensitive)
        }
        return newString
    }
}
