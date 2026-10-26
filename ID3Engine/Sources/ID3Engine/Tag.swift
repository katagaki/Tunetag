//
//  Tag.swift
//  ID3Engine
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import Foundation

/// Editable tag values. Nil means "leave unchanged" when writing, and an empty string removes the field.
public struct Tag: Equatable, Sendable {

    public var albumArt: Data?
    public var title: String?
    public var artist: String?
    public var album: String?
    public var albumArtist: String?
    public var year: String?
    public var track: String?
    public var trackTotal: String?
    public var genre: String?
    public var composer: String?
    public var discNumber: String?
    public var discTotal: String?
    public var grouping: String?
    public var bpm: String?
    public var isCompilation: Bool?
    public var comment: String?
    public var lyrics: String?
    public var titleSortOrder: String?
    public var artistSortOrder: String?
    public var albumSortOrder: String?
    public var albumArtistSortOrder: String?
    public var composerSortOrder: String?
    public var conductor: String?
    public var publisher: String?
    public var copyright: String?
    public var encodedBy: String?

    // Read-only
    public var isrc: String?
    public var musicBrainzReleaseID: String?
    public var musicBrainzRecordingID: String?
    public var replayGainTrackGain: String?
    public var replayGainTrackPeak: String?
    public var replayGainAlbumGain: String?
    public var replayGainAlbumPeak: String?

    public var hasValidNumbers: Bool {
        [track, trackTotal, discNumber, discTotal, bpm].allSatisfy { value in
            guard let value, !value.isEmpty else { return true }
            return value.allSatisfy { "0"..."9" ~= $0 } && Int(value) != nil
        }
    }

    public var hasSortOrders: Bool {
        [titleSortOrder, artistSortOrder, albumSortOrder, albumArtistSortOrder, composerSortOrder]
            .contains { !($0 ?? "").isEmpty }
    }

    public var hasIdentifiers: Bool {
        [isrc, musicBrainzReleaseID, musicBrainzRecordingID].contains { !($0 ?? "").isEmpty }
    }

    public var hasReplayGain: Bool {
        [replayGainTrackGain, replayGainTrackPeak, replayGainAlbumGain, replayGainAlbumPeak]
            .contains { !($0 ?? "").isEmpty }
    }

    public init() { }

    public init(from tagCombined: TagSnapshot) {
        albumArt = tagCombined.albumArt
        title = tagCombined.title
        artist = tagCombined.artist
        album = tagCombined.album
        albumArtist = tagCombined.albumArtist
        year = tagCombined.year
        track = tagCombined.track.map(String.init)
        trackTotal = tagCombined.trackTotal.map(String.init)
        genre = tagCombined.genre
        composer = tagCombined.composer
        discNumber = tagCombined.discNumber.map(String.init)
        discTotal = tagCombined.discTotal.map(String.init)
        grouping = tagCombined.grouping
        bpm = tagCombined.bpm.map(String.init)
        isCompilation = tagCombined.isCompilation
        comment = tagCombined.comment
        lyrics = tagCombined.lyrics
        titleSortOrder = tagCombined.titleSortOrder
        artistSortOrder = tagCombined.artistSortOrder
        albumSortOrder = tagCombined.albumSortOrder
        albumArtistSortOrder = tagCombined.albumArtistSortOrder
        composerSortOrder = tagCombined.composerSortOrder
        conductor = tagCombined.conductor
        publisher = tagCombined.publisher
        copyright = tagCombined.copyright
        encodedBy = tagCombined.encodedBy
        isrc = tagCombined.isrc
        musicBrainzReleaseID = tagCombined.musicBrainzReleaseID
        musicBrainzRecordingID = tagCombined.musicBrainzRecordingID
        replayGainTrackGain = tagCombined.replayGainTrackGain
        replayGainTrackPeak = tagCombined.replayGainTrackPeak
        replayGainAlbumGain = tagCombined.replayGainAlbumGain
        replayGainAlbumPeak = tagCombined.replayGainAlbumPeak
    }
}
