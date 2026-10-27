//
//  AutomaticLookup.swift
//  PreludeLookup
//

import Foundation

/// Finds the album that files belong to without the user choosing a source.
///
/// Songs are recognized by their audio with Shazam, then their album is looked up on iTunes, and on MusicBrainz if
/// iTunes doesn't have it. If no songs are recognized, an album can be looked up by its artist and name instead.
public enum AutomaticLookup {

    public struct Result: Sendable {
        /// Albums found, with the most likely first.
        public var releases: [OnlineRelease]
        /// The album that clearly fits best, if there is one.
        public var bestMatch: OnlineRelease?
        /// Track IDs recognized for each file, by path, so files can be matched to their exact tracks.
        public var identifiers: [String: Set<String>]

        public init(releases: [OnlineRelease] = [],
                    bestMatch: OnlineRelease? = nil,
                    identifiers: [String: Set<String>] = [:]) {
            self.releases = releases
            self.bestMatch = bestMatch
            self.identifiers = identifiers
        }
    }

    /// Recognizes the files and finds their album. Returns no releases if no songs are recognized,
    /// since files often have no tags to search for until they are looked up.
    public static func lookUp(filesAt paths: [String],
                              country: String = LookupSource.defaultCountry) async -> Result {
        let songs = await AudioRecognizer.recognize(filesAt: paths)
        guard !songs.isEmpty else { return Result() }
        if let result = try? await iTunesReleases(for: songs, country: country), !result.releases.isEmpty {
            return result
        }
        if let result = try? await musicBrainzReleases(for: songs), !result.releases.isEmpty {
            return result
        }
        return Result()
    }

    /// Finds the single album that best matches an artist and album name, from iTunes, or MusicBrainz if iTunes
    /// doesn't have it. Returns nil if neither has a match.
    public static func lookUp(artist: String,
                              album: String,
                              country: String = LookupSource.defaultCountry) async throws -> OnlineRelease? {
        guard !artist.isEmpty || !album.isEmpty else { return nil }
        if let release = try? await LookupSource.iTunes.search(artist: artist, album: album, country: country).first {
            return release
        }
        return try await LookupSource.musicBrainz.search(artist: artist, album: album).first
    }

    static func iTunesReleases(for songs: [RecognizedSong], country: String) async throws -> Result {
        let found = try await ITunesLookup.releases(for: songs, country: country)
        return Result(releases: found.ranked.map(\.0), bestMatch: bestMatch(found.ranked), identifiers: found.identifiers)
    }

    static func musicBrainzReleases(for songs: [RecognizedSong]) async throws -> Result {
        // Each song's recordings, found by ISRC, or by title for songs without one on MusicBrainz
        var recordingsBySong: [String: [MusicBrainzLookup.RecordingMatch]] = [:]
        let isrcRecordings = try await MusicBrainzLookup.recordings(isrcs: songs.compactMap(\.isrc))
        for song in songs {
            guard let isrc = song.isrc else { continue }
            let recordings = isrcRecordings.filter { $0.isrcs.contains { $0.caseInsensitiveCompare(isrc) == .orderedSame } }
            if !recordings.isEmpty {
                recordingsBySong[song.path] = recordings
            }
        }
        if recordingsBySong.isEmpty, let song = songs.first, let title = song.title {
            recordingsBySong[song.path] = try await MusicBrainzLookup.recordings(title: title, artist: song.artist)
        }

        var identifiers: [String: Set<String>] = [:]
        var counts: [String: Int] = [:]
        var releasesByID: [String: OnlineRelease] = [:]
        var order: [String] = []
        for (path, recordings) in recordingsBySong {
            identifiers[path] = Set(recordings.map(\.recordingID))
            // Count each release once per song, even if the song has several recordings on it
            var releasesForSong = Set<String>()
            for release in recordings.flatMap(\.releases) where releasesForSong.insert(release.id).inserted {
                if releasesByID[release.id] == nil {
                    releasesByID[release.id] = release
                    order.append(release.id)
                }
                counts[release.id, default: 0] += 1
            }
        }
        let ranked = order
            .compactMap { id in releasesByID[id].map { ($0, counts[id] ?? 0) } }
            .sorted { $0.1 > $1.1 }
        return Result(releases: ranked.map(\.0), bestMatch: bestMatch(ranked), identifiers: identifiers)
    }

    /// The album with the most recognized songs, if no other album has as many.
    static func bestMatch(_ ranked: [(OnlineRelease, Int)]) -> OnlineRelease? {
        guard let first = ranked.first else { return nil }
        if ranked.count == 1 || first.1 > ranked[1].1 {
            return first.0
        }
        return nil
    }
}
