//
//  TagSnapshot.swift
//  ID3Engine
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import Foundation

/// Typed tag values read from a file, or the values shared by several files.
public struct TagSnapshot: Sendable {

    public var albumArt: Data?
    public var title, artist, album, albumArtist, genre, composer, year, grouping: String?
    public var track, trackTotal, discNumber, discTotal, bpm: Int?
    public var isCompilation: Bool?
    public var comment, lyrics: String?
    public var titleSortOrder, artistSortOrder, albumSortOrder, albumArtistSortOrder, composerSortOrder: String?
    public var conductor, publisher, copyright, encodedBy: String?

    // Read-only
    public var isrc, musicBrainzReleaseID, musicBrainzRecordingID: String?
    public var replayGainTrackGain, replayGainTrackPeak, replayGainAlbumGain, replayGainAlbumPeak: String?

    public init(_ file: TagLibFile) {
        let properties = file.properties
        func value(_ key: String) -> String? {
            properties[key]?.first
        }

        let trackParts = TagSnapshot.numberParts(value(TagKey.trackNumber))
        let discParts = TagSnapshot.numberParts(value(TagKey.discNumber))

        title = value(TagKey.title)
        artist = value(TagKey.artist)
        album = value(TagKey.album)
        albumArtist = value(TagKey.albumArtist)
        year = value(TagKey.date)
        track = trackParts.number
        trackTotal = trackParts.total ?? TagKey.trackTotals.lazy.compactMap { value($0) }.compactMap { Int($0) }.first
        discNumber = discParts.number
        discTotal = discParts.total ?? TagKey.discTotals.lazy.compactMap { value($0) }.compactMap { Int($0) }.first
        genre = value(TagKey.genre)
        composer = value(TagKey.composer)
        grouping = value(TagKey.grouping)
        bpm = value(TagKey.bpm).flatMap { Int($0) }
        isCompilation = value(TagKey.compilation).map { $0 == "1" || $0.lowercased() == "true" } ?? false
        comment = value(TagKey.comment)
        lyrics = value(TagKey.lyrics)
        titleSortOrder = value(TagKey.titleSort)
        artistSortOrder = value(TagKey.artistSort)
        albumSortOrder = value(TagKey.albumSort)
        albumArtistSortOrder = value(TagKey.albumArtistSort)
        composerSortOrder = value(TagKey.composerSort)
        conductor = value(TagKey.conductor)
        publisher = value(TagKey.publisher)
        copyright = value(TagKey.copyright)
        encodedBy = value(TagKey.encodedBy)
        isrc = value(TagKey.isrc)
        musicBrainzReleaseID = value(TagKey.musicBrainzReleaseID)
        musicBrainzRecordingID = value(TagKey.musicBrainzRecordingID)
        replayGainTrackGain = value(TagKey.replayGainTrackGain)
        replayGainTrackPeak = value(TagKey.replayGainTrackPeak)
        replayGainAlbumGain = value(TagKey.replayGainAlbumGain)
        replayGainAlbumPeak = value(TagKey.replayGainAlbumPeak)
        albumArt = file.frontCover
    }

    /// Reads the files at the given paths, keeping only the values they all share.
    /// Returns nil if none of the files could be read.
    public static func read(paths: [String]) -> TagSnapshot? {
        var snapshot: TagSnapshot?
        for path in paths {
            guard let file = TagLibFile(path: path) else { continue }
            let fileSnapshot = TagSnapshot(file)
            if snapshot == nil {
                snapshot = fileSnapshot
            } else {
                snapshot!.merge(with: fileSnapshot)
            }
        }
        return snapshot
    }

    /// Keeps only the values that are shared with the other file; differing values become nil.
    public mutating func merge(with other: TagSnapshot) {
        title = Self.shared(title, other.title)
        artist = Self.shared(artist, other.artist)
        album = Self.shared(album, other.album)
        albumArtist = Self.shared(albumArtist, other.albumArtist)
        year = Self.shared(year, other.year)
        track = Self.shared(track, other.track)
        trackTotal = Self.shared(trackTotal, other.trackTotal)
        discNumber = Self.shared(discNumber, other.discNumber)
        discTotal = Self.shared(discTotal, other.discTotal)
        genre = Self.shared(genre, other.genre)
        composer = Self.shared(composer, other.composer)
        grouping = Self.shared(grouping, other.grouping)
        bpm = Self.shared(bpm, other.bpm)
        isCompilation = Self.shared(isCompilation, other.isCompilation)
        comment = Self.shared(comment, other.comment)
        lyrics = Self.shared(lyrics, other.lyrics)
        titleSortOrder = Self.shared(titleSortOrder, other.titleSortOrder)
        artistSortOrder = Self.shared(artistSortOrder, other.artistSortOrder)
        albumSortOrder = Self.shared(albumSortOrder, other.albumSortOrder)
        albumArtistSortOrder = Self.shared(albumArtistSortOrder, other.albumArtistSortOrder)
        composerSortOrder = Self.shared(composerSortOrder, other.composerSortOrder)
        conductor = Self.shared(conductor, other.conductor)
        publisher = Self.shared(publisher, other.publisher)
        copyright = Self.shared(copyright, other.copyright)
        encodedBy = Self.shared(encodedBy, other.encodedBy)
        isrc = Self.shared(isrc, other.isrc)
        musicBrainzReleaseID = Self.shared(musicBrainzReleaseID, other.musicBrainzReleaseID)
        musicBrainzRecordingID = Self.shared(musicBrainzRecordingID, other.musicBrainzRecordingID)
        replayGainTrackGain = Self.shared(replayGainTrackGain, other.replayGainTrackGain)
        replayGainTrackPeak = Self.shared(replayGainTrackPeak, other.replayGainTrackPeak)
        replayGainAlbumGain = Self.shared(replayGainAlbumGain, other.replayGainAlbumGain)
        replayGainAlbumPeak = Self.shared(replayGainAlbumPeak, other.replayGainAlbumPeak)
        albumArt = Self.shared(albumArt, other.albumArt)
    }

    private static func shared<T: Equatable>(_ lhs: T?, _ rhs: T?) -> T? {
        lhs == rhs ? lhs : nil
    }

    /// Splits values such as "5/12" into the number and the total.
    public static func numberParts(_ value: String?) -> (number: Int?, total: Int?) {
        guard let value else { return (nil, nil) }
        let parts = value.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        let number = parts.first.flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        let total = parts.count > 1 ? Int(parts[1].trimmingCharacters(in: .whitespaces)) : nil
        return (number == 0 ? nil : number, total)
    }
}
