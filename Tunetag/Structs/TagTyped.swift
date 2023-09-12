//
//  TagTyped.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import AVFoundation
import Foundation
import ID3TagEditor

struct TagTyped {

    var albumArt: Data?
    var title, artist, album, albumArtist, genre, composer: String?
    var year, track, discNumber: Int?

    init(_ file: FSFile, reader tagContentReader: ID3TagContentReader) async {
        title = tagContentReader.title() ?? ""
        artist = tagContentReader.artist() ?? ""
        album = tagContentReader.album() ?? ""
        albumArtist = tagContentReader.albumArtist() ?? ""
        if let yearFromTag = tagContentReader.recordingYear() {
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
        } else if let albumArtFromTag = tagContentReader.attachedPictures().first {
            albumArt = albumArtFromTag.picture
        } else {
            albumArt = await albumArtUsingAVPlayer(file: file)
        }
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    mutating func merge(with file: FSFile, reader tagContentReader: ID3TagContentReader) async {
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
        if let yearFromTag = tagContentReader.recordingYear(), year != yearFromTag {
            year = nil
        } else if tagContentReader.recordingYear() == nil && year != nil {
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
        } else if let albumArtFromTag = tagContentReader.attachedPictures().first {
            if albumArt != albumArtFromTag.picture {
                albumArt = nil
            }
        } else if let albumArtFromTag = await albumArtUsingAVPlayer(file: file) {
            if albumArt != albumArtFromTag {
                albumArt = nil
            }
        } else {
            if albumArt != nil {
                albumArt = nil
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    func albumArtUsingAVPlayer(file: FSFile) async -> Data? {
        do {
            let playerItem = AVPlayerItem(url: URL(filePath: file.path))
            let metadataList = try await playerItem.asset.load(.metadata)
            for item in metadataList {
                switch item.commonKey {
                case .commonKeyArtwork?:
                    if let data = try await item.load(.dataValue) {
                        return data
                    }
                default: break
                }
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        return nil
    }
}
