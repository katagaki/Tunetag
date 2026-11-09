//
//  TagSummary.swift
//  Tunetag
//

import Foundation
import Prelude

/// The tag values the List view shows for a file.
struct TagSummary: Sendable {

    private let values: [ListColumn: String]
    private let dates: [ListColumn: Date]

    init(reading file: FSFile) {
        var values: [ListColumn: String] = [.fileName: file.name]
        if let tagFile = TagLibFile(path: file.path) {
            let snapshot = TagSnapshot(tagFile)
            values[.title] = snapshot.title
            values[.artist] = snapshot.artist
            values[.album] = snapshot.album
            values[.albumArtist] = snapshot.albumArtist
            values[.year] = snapshot.year
            values[.trackNumber] = snapshot.track.map(String.init)
            values[.discNumber] = snapshot.discNumber.map(String.init)
            values[.genre] = snapshot.genre
            values[.composer] = snapshot.composer
        }
        let resourceValues = try? URL(filePath: file.path)
            .resourceValues(forKeys: [.addedToDirectoryDateKey, .contentModificationDateKey])
        var dates: [ListColumn: Date] = [:]
        dates[.dateAdded] = resourceValues?.addedToDirectoryDate
        dates[.dateModified] = resourceValues?.contentModificationDate
        for (column, date) in dates {
            values[column] = date.formatted(date: .abbreviated, time: .shortened)
        }
        self.values = values
        self.dates = dates
    }

    func value(for column: ListColumn) -> String {
        values[column] ?? ""
    }

    func date(for column: ListColumn) -> Date? {
        dates[column]
    }
}
