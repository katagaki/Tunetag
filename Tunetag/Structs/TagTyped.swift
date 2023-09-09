//
//  TagTyped.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import Foundation
import ID3TagEditor

struct TagTyped {

    var albumArt: Data?
    var title, artist, album, albumArtist, genre, composer: String?
    var year, track, discNumber: Int?

    init(reader tagContentReader: ID3TagContentReader) {
        title = tagContentReader.title() ?? ""
        artist = tagContentReader.artist() ?? ""
        album = tagContentReader.album() ?? ""
        albumArtist = tagContentReader.albumArtist() ?? ""
        if let yearFromTag = tagContentReader.recordingDateTime()?.year {
            year = yearFromTag
        }
        if let trackFromTag = tagContentReader.trackPosition()?.position {
            track = trackFromTag
        }
        genre = tagContentReader.genre()?.description ?? ""
        composer = tagContentReader.composer() ?? ""
        if let discNumberFromTag = tagContentReader.discPosition()?.position {
            discNumber = discNumberFromTag
        }
        if let albumArtFromTag = tagContentReader.attachedPictures()
                .first(where: { $0.type == .frontCover }) {
            albumArt = albumArtFromTag.picture
        }
    }

    mutating func merge(with tagContentReader: ID3TagContentReader) {
        if title != tagContentReader.title() ?? "" {
            title = nil
        }
        if artist != tagContentReader.artist() ?? "" {
            artist = nil
        }
        if album != tagContentReader.album() ?? "" {
            album = nil
        }
        if albumArtist != tagContentReader.albumArtist() ?? "" {
            albumArtist = nil
        }
        if let yearFromTag = tagContentReader.recordingDateTime()?.year, year != yearFromTag {
            year = nil
        } else if tagContentReader.recordingDateTime()?.year == nil && year != nil {
            year = nil
        }
        if let trackFromTag = tagContentReader.trackPosition()?.position, track != trackFromTag {
            track = nil
        } else if tagContentReader.trackPosition()?.position == nil && track != nil {
            track = nil
        }
        if genre != tagContentReader.genre()?.description ?? "" {
            genre = nil
        }
        if composer != tagContentReader.composer() ?? "" {
            composer = nil
        }
        if let discNumberFromTag = tagContentReader.discPosition()?.position,
           discNumber != discNumberFromTag {
            discNumber = nil
        } else if tagContentReader.discPosition()?.position == nil && discNumber != nil {
            discNumber = nil
        }
        if let albumArtFromTag = tagContentReader.attachedPictures().first(where: { picture in
            picture.type == .frontCover
        }) {
            if albumArt != albumArtFromTag.picture {
                albumArt = nil
            }
        } else {
            if albumArt != nil {
                albumArt = nil
            }
        }
    }
}
