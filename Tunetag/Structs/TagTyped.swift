//
//  TagTyped.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import Foundation
import SFBAudioEngine

struct TagTyped {

    var albumArt: Data?
    var title, artist, album, albumArtist, genre, composer, year: String?
    var track, discNumber: Int?

    init(_ file: FSFile, metadata: AudioMetadata) {
        title = metadata.title
        artist = metadata.artist
        album = metadata.albumTitle
        albumArtist = metadata.albumArtist
        year = metadata.releaseDate
        track = metadata.trackNumber
        discNumber = metadata.discNumber
        genre = metadata.genre
        composer = metadata.composer
        albumArt = TagTyped.albumArtData(from: metadata)
    }

    mutating func merge(with file: FSFile, metadata: AudioMetadata) {
        if title != metadata.title {
            title = nil
        }
        if artist != metadata.artist {
            artist = nil
        }
        if album != metadata.albumTitle {
            album = nil
        }
        if albumArtist != metadata.albumArtist {
            albumArtist = nil
        }
        if year != metadata.releaseDate {
            year = nil
        }
        if track != metadata.trackNumber {
            track = nil
        }
        if discNumber != metadata.discNumber {
            discNumber = nil
        }
        if genre != metadata.genre {
            genre = nil
        }
        if composer != metadata.composer {
            composer = nil
        }
        if albumArt != TagTyped.albumArtData(from: metadata) {
            albumArt = nil
        }
    }

    static func albumArtData(from metadata: AudioMetadata) -> Data? {
        if let frontCover = metadata.attachedPictures(ofType: .frontCover).first {
            return frontCover.imageData
        }
        return metadata.attachedPictures.first?.imageData
    }
}
