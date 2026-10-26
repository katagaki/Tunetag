//
//  FocusedField.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import Foundation

/// Editable fields, declared in the order that the return key moves focus through them.
enum FocusedField: Hashable, CaseIterable {
    case title
    case artist
    case composer
    case conductor
    case genre
    case grouping
    case bpm
    case album
    case albumArtist
    case year
    case trackNumber
    case trackTotal
    case discNumber
    case discTotal
    case publisher
    case copyright
    case encodedBy
    case comment
    case lyrics
    case titleSortOrder
    case artistSortOrder
    case albumSortOrder
    case albumArtistSortOrder
    case composerSortOrder

    var next: FocusedField? {
        let allCases = FocusedField.allCases
        guard let index = allCases.firstIndex(of: self), index + 1 < allCases.count else { return nil }
        return allCases[index + 1]
    }
}
