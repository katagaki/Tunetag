//
//  FocusedField.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import Foundation
import Prelude

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

    /// The tag value that the field edits.
    var keyPath: WritableKeyPath<Tag, String?> {
        switch self {
        case .title: \.title
        case .artist: \.artist
        case .composer: \.composer
        case .conductor: \.conductor
        case .genre: \.genre
        case .grouping: \.grouping
        case .bpm: \.bpm
        case .album: \.album
        case .albumArtist: \.albumArtist
        case .year: \.year
        case .trackNumber: \.track
        case .trackTotal: \.trackTotal
        case .discNumber: \.discNumber
        case .discTotal: \.discTotal
        case .publisher: \.publisher
        case .copyright: \.copyright
        case .encodedBy: \.encodedBy
        case .comment: \.comment
        case .lyrics: \.lyrics
        case .titleSortOrder: \.titleSortOrder
        case .artistSortOrder: \.artistSortOrder
        case .albumSortOrder: \.albumSortOrder
        case .albumArtistSortOrder: \.albumArtistSortOrder
        case .composerSortOrder: \.composerSortOrder
        }
    }

    var next: FocusedField? {
        let allCases = FocusedField.allCases
        guard let index = allCases.firstIndex(of: self), index + 1 < allCases.count else { return nil }
        return allCases[index + 1]
    }
}
