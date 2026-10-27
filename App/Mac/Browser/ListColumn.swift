//
//  ListColumn.swift
//  Tunetag
//

import Foundation

enum ListColumn: String, CaseIterable, Identifiable, Sendable {
    case fileName, title, artist, album, albumArtist, year, trackNumber, discNumber, genre, composer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fileName: MacText.string("Column.FileName")
        case .title: MacText.shared("Tag.Title")
        case .artist: MacText.shared("Tag.Artist")
        case .album: MacText.shared("Tag.Album")
        case .albumArtist: MacText.shared("Tag.AlbumArtist")
        case .year: MacText.shared("Tag.Year")
        case .trackNumber: MacText.shared("Tag.Track")
        case .discNumber: MacText.shared("Tag.Disc")
        case .genre: MacText.shared("Tag.Genre")
        case .composer: MacText.shared("Tag.Composer")
        }
    }

    var symbolName: String {
        switch self {
        case .fileName: "doc"
        case .title: "music.note"
        case .artist: "music.mic"
        case .album: "square.stack"
        case .albumArtist: "person.2"
        case .year: "calendar"
        case .trackNumber: "number"
        case .discNumber: "opticaldisc"
        case .genre: "guitars"
        case .composer: "music.quarternote.3"
        }
    }

    var defaultWidth: CGFloat {
        switch self {
        case .fileName, .title, .album: 200
        case .artist, .albumArtist, .composer: 150
        case .genre: 110
        case .year, .trackNumber, .discNumber: 70
        }
    }

    var isNumeric: Bool {
        self == .year || self == .trackNumber || self == .discNumber
    }
}
