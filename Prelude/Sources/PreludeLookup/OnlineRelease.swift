//
//  OnlineRelease.swift
//  PreludeLookup
//

import Foundation

/// An album found in an online source's search results.
public struct OnlineRelease: Identifiable, Hashable, Sendable {
    public var id: String
    public var source: LookupSource
    /// The store that the release was found in, for sources with regional stores.
    public var country: String?
    public var title: String
    public var artist: String
    public var year: String?
    public var trackCount: Int?
    /// Extra details that tell similar releases apart, such as the format and country.
    public var details: [String]
    public var thumbnailURL: URL?
    public var artworkURL: URL?

    public init(id: String,
                source: LookupSource,
                country: String? = nil,
                title: String,
                artist: String,
                year: String? = nil,
                trackCount: Int? = nil,
                details: [String] = [],
                thumbnailURL: URL? = nil,
                artworkURL: URL? = nil) {
        self.id = id
        self.source = source
        self.country = country
        self.title = title
        self.artist = artist
        self.year = year
        self.trackCount = trackCount
        self.details = details
        self.thumbnailURL = thumbnailURL
        self.artworkURL = artworkURL
    }
}

/// A track on an online release.
public struct OnlineTrack: Identifiable, Hashable, Sendable {
    public var title: String
    public var artist: String
    public var number: Int
    public var disc: Int
    public var duration: TimeInterval?
    /// The iTunes Store's ID for the song, which is also its Apple Music ID.
    public var storeID: String?
    /// The MusicBrainz recording ID.
    public var recordingID: String?

    public var id: String {
        "\(disc)-\(number)"
    }

    public init(title: String,
                artist: String,
                number: Int,
                disc: Int = 1,
                duration: TimeInterval? = nil,
                storeID: String? = nil,
                recordingID: String? = nil) {
        self.title = title
        self.artist = artist
        self.number = number
        self.disc = disc
        self.duration = duration
        self.storeID = storeID
        self.recordingID = recordingID
    }
}

/// An online release with its tracks and album-level values.
public struct OnlineReleaseDetail: Sendable {
    public var release: OnlineRelease
    public var tracks: [OnlineTrack]
    public var genre: String?
    public var copyright: String?
    public var publisher: String?

    public var discTotal: Int {
        tracks.map(\.disc).max() ?? 1
    }

    public init(release: OnlineRelease,
                tracks: [OnlineTrack],
                genre: String? = nil,
                copyright: String? = nil,
                publisher: String? = nil) {
        self.release = release
        self.tracks = tracks
        self.genre = genre
        self.copyright = copyright
        self.publisher = publisher
    }

    public func trackTotal(onDisc disc: Int) -> Int {
        tracks.filter { $0.disc == disc }.map(\.number).max() ?? 0
    }
}

public enum LookupError: Error {
    case badResponse
}
