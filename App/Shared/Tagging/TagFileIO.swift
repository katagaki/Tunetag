//
//  TagFileIO.swift
//  Tunetag
//

import Foundation
import Prelude
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Writes tags to files, shared by the iOS editor and the Mac inspector.
enum TagFileIO {

    nonisolated static func save(_ tag: Tag, to file: FSFile, albumArtRemoved: Bool) async -> Bool {
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

    nonisolated private static func sanitizedImageData(_ data: Data) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        if let pngData = image.pngData() {
            return pngData
        }
        return image.jpegData(compressionQuality: 1.0)
        #else
        guard let bitmap = NSImage(data: data)?.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:)) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
            ?? bitmap.representation(using: .jpeg, properties: [.compressionFactor: 1.0])
        #endif
    }
}
