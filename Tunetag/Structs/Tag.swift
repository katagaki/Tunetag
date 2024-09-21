//
//  Tag.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import Foundation

struct Tag {

    var albumArt: Data?
    var title: String?
    var artist: String?
    var album: String?
    var albumArtist: String?
    var year: String?
    var track: String?
    var genre: String?
    var composer: String?
    var discNumber: String?

    init() { }

    init(from tagCombined: TagTyped) {
        albumArt = tagCombined.albumArt
        title = tagCombined.title
        artist = tagCombined.artist
        album = tagCombined.album
        albumArtist = tagCombined.albumArtist
        if let year = tagCombined.year {
            self.year = String(year)
        }
        if let track = tagCombined.track {
            self.track = String(track)
        }
        genre = tagCombined.genre
        composer = tagCombined.composer
        if let discNumber = tagCombined.discNumber {
            self.discNumber = String(discNumber)
        }
    }
}
