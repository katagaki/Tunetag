//
//  TagWriter.swift
//  ID3Engine
//

import Foundation

public enum TagWriter {

    /// Applies edited values to a file. Nil values are left unchanged, and empty values remove the field.
    /// - Parameters:
    ///   - albumArt: Image data for the new front cover, or nil to keep the current one.
    ///   - albumArtRemoved: Removes the front cover when no new album art is given.
    ///   - transform: Applied to free-text fields before writing, such as to expand tokens.
    public static func apply(_ tag: Tag,
                             to tagFile: TagLibFile,
                             albumArt: Data? = nil,
                             albumArtRemoved: Bool = false,
                             transform: (String) -> String = { $0 }) {
        let textFields: [(String, String?)] = [
            (TagKey.title, tag.title),
            (TagKey.artist, tag.artist),
            (TagKey.album, tag.album),
            (TagKey.albumArtist, tag.albumArtist),
            (TagKey.composer, tag.composer),
            (TagKey.grouping, tag.grouping),
            (TagKey.comment, tag.comment),
            (TagKey.titleSort, tag.titleSortOrder),
            (TagKey.artistSort, tag.artistSortOrder),
            (TagKey.albumSort, tag.albumSortOrder),
            (TagKey.albumArtistSort, tag.albumArtistSortOrder),
            (TagKey.composerSort, tag.composerSortOrder),
            (TagKey.conductor, tag.conductor),
            (TagKey.publisher, tag.publisher),
            (TagKey.copyright, tag.copyright),
            (TagKey.encodedBy, tag.encodedBy)
        ]
        for (key, value) in textFields {
            if let value {
                setValue(transform(value), for: key, in: tagFile)
            }
        }

        // Fields that don't support tokens
        let plainFields: [(String, String?)] = [
            (TagKey.date, tag.year),
            (TagKey.genre, tag.genre),
            (TagKey.bpm, tag.bpm),
            (TagKey.lyrics, tag.lyrics)
        ]
        for (key, value) in plainFields {
            if let value {
                setValue(value, for: key, in: tagFile)
            }
        }

        if let isCompilation = tag.isCompilation {
            // Remove the flag instead of writing false, since some apps treat its presence as true
            setValue(isCompilation ? "1" : "", for: TagKey.compilation, in: tagFile)
        }

        applyNumberPair(to: tagFile, numberKey: TagKey.trackNumber, totalKeys: TagKey.trackTotals,
                        number: tag.track, total: tag.trackTotal)
        applyNumberPair(to: tagFile, numberKey: TagKey.discNumber, totalKeys: TagKey.discTotals,
                        number: tag.discNumber, total: tag.discTotal)

        if let albumArt {
            tagFile.setFrontCover(albumArt)
        } else if albumArtRemoved {
            tagFile.setFrontCover(nil)
        }
    }

    /// Writes a number and total, keeping whichever half wasn't edited.
    private static func applyNumberPair(to tagFile: TagLibFile,
                                        numberKey: String,
                                        totalKeys: [String],
                                        number: String?,
                                        total: String?) {
        guard number != nil || total != nil else { return }
        let properties = tagFile.properties
        let current = TagSnapshot.numberParts(properties[numberKey]?.first)
        let currentTotal = current.total ??
            totalKeys.lazy.compactMap { properties[$0]?.first }.first.flatMap { Int($0) }
        let newNumber = number ?? current.number.map(String.init) ?? ""
        let newTotal = total ?? currentTotal.map(String.init) ?? ""

        if tagFile.usesSeparateTotals {
            setValue(newNumber, for: numberKey, in: tagFile)
            setValue(newTotal, for: totalKeys[0], in: tagFile)
            for key in totalKeys.dropFirst() where properties[key] != nil {
                setValue("", for: key, in: tagFile)
            }
        } else {
            let combined = newTotal.isEmpty ? newNumber : "\(newNumber.isEmpty ? "0" : newNumber)/\(newTotal)"
            setValue(combined, for: numberKey, in: tagFile)
            for key in totalKeys where properties[key] != nil {
                setValue("", for: key, in: tagFile)
            }
        }
    }

    private static func setValue(_ value: String, for key: String, in tagFile: TagLibFile) {
        tagFile.setValues(value.isEmpty ? nil : [value], forProperty: key)
    }
}
