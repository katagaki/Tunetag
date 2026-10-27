//
//  LookupField+Name.swift
//  Tunetag
//

import Foundation
import PreludeLookup

extension LookupField {

    var name: LocalizedStringResource {
        switch self {
        case .title: return "Tag.Title"
        case .artist: return "Tag.Artist"
        case .album: return "Tag.Album"
        case .albumArtist: return "Tag.AlbumArtist"
        case .year: return "Tag.Year"
        case .track: return "Tag.Track"
        case .disc: return "Tag.Disc"
        case .genre: return "Tag.Genre"
        case .albumArt: return "OnlineLookup.AlbumArt"
        case .publisher: return "Tag.Publisher"
        case .copyright: return "Tag.Copyright"
        case .musicBrainzIDs: return "OnlineLookup.MusicBrainzIDs"
        }
    }
}
