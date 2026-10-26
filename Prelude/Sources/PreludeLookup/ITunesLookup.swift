//
//  ITunesLookup.swift
//  PreludeLookup
//

import Foundation

/// Looks up albums with the iTunes Search API, which doesn't need an API key.
enum ITunesLookup {

    private struct Response: Decodable {
        var results: [Result]
    }

    private struct Result: Decodable {
        var wrapperType: String
        var kind: String?
        var collectionId: Int?
        var collectionName: String?
        var collectionArtistName: String?
        var trackId: Int?
        var artistName: String?
        var trackName: String?
        var trackNumber: Int?
        var discNumber: Int?
        var trackCount: Int?
        var trackTimeMillis: Double?
        var artworkUrl100: String?
        var releaseDate: String?
        var primaryGenreName: String?
        var copyright: String?
    }

    static func search(artist: String, album: String, country: String) async throws -> [OnlineRelease] {
        let term = [artist, album].filter { !$0.isEmpty }.joined(separator: " ")
        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "entity", value: "album"),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "limit", value: "50")
        ]
        let response = try await fetch(components.url!)
        return response.results.compactMap { release(from: $0, country: country) }
    }

    static func detail(for release: OnlineRelease) async throws -> OnlineReleaseDetail {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")!
        components.queryItems = [
            URLQueryItem(name: "id", value: release.id),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "country", value: release.country ?? "US"),
            // Lookups return 50 results unless asked for more, which cuts off longer albums
            URLQueryItem(name: "limit", value: "200")
        ]
        let response = try await fetch(components.url!)
        guard let collection = response.results.first(where: { $0.wrapperType == "collection" }) else {
            throw LookupError.badResponse
        }
        let tracks = response.results
            .filter { $0.wrapperType == "track" && $0.kind == "song" }
            .compactMap { result -> OnlineTrack? in
                guard let title = result.trackName, let number = result.trackNumber else { return nil }
                return OnlineTrack(title: title,
                                   artist: result.artistName ?? release.artist,
                                   number: number,
                                   disc: result.discNumber ?? 1,
                                   duration: result.trackTimeMillis.map { $0 / 1000.0 },
                                   storeID: result.trackId.map(String.init))
            }
            .sorted { ($0.disc, $0.number) < ($1.disc, $1.number) }
        return OnlineReleaseDetail(release: self.release(from: collection, country: release.country) ?? release,
                                   tracks: tracks,
                                   genre: collection.primaryGenreName,
                                   copyright: collection.copyright)
    }

    /// The albums that recognized songs are on, and the store IDs of each file's song.
    struct SongReleases {
        var ranked: [(OnlineRelease, Int)]
        var identifiers: [String: Set<String>]
    }

    /// Finds the albums that recognized songs are on, ordered by how many of the songs each album has.
    /// Songs are looked up by their Apple Music ID, or searched for by title and artist when Shazam doesn't have one.
    /// Falls back to the US store for songs that aren't sold in the given one.
    static func releases(for songs: [RecognizedSong], country: String) async throws -> SongReleases {
        let result = try await releases(for: songs, inStore: country)
        if result.ranked.isEmpty && country != "US" {
            return try await releases(for: songs, inStore: "US")
        }
        return result
    }

    private static func releases(for songs: [RecognizedSong], inStore country: String) async throws -> SongReleases {
        var tracksBySong: [String: [Result]] = [:]
        let songIDs = songs.compactMap(\.appleMusicID)
        if !songIDs.isEmpty {
            let tracks = try await lookup(ids: songIDs, country: country).filter { $0.wrapperType == "track" }
            for song in songs {
                guard let songID = song.appleMusicID else { continue }
                tracksBySong[song.path] = tracks.filter { $0.trackId.map(String.init) == songID }
            }
        }
        for song in songs where song.appleMusicID == nil {
            guard let title = song.title else { continue }
            tracksBySong[song.path] = try await searchSongs(title: title, artist: song.artist, country: country)
        }

        var counts: [Int: Int] = [:]
        var order: [Int] = []
        var identifiers: [String: Set<String>] = [:]
        for song in songs {
            guard let tracks = tracksBySong[song.path], !tracks.isEmpty else { continue }
            identifiers[song.path] = Set(tracks.compactMap { $0.trackId.map(String.init) })
            // Count each album once per song, even if the song appears on it more than once
            var albumsForSong = Set<Int>()
            for collectionID in tracks.compactMap(\.collectionId) where albumsForSong.insert(collectionID).inserted {
                if counts[collectionID] == nil {
                    order.append(collectionID)
                }
                counts[collectionID, default: 0] += 1
            }
        }
        guard !order.isEmpty else { return SongReleases(ranked: [], identifiers: identifiers) }
        // Lookups accept up to 200 IDs
        let collections = try await lookup(ids: order.prefix(200).map(String.init), country: country)
        let ranked = order
            .compactMap { collectionID in
                collections.first { $0.wrapperType == "collection" && $0.collectionId == collectionID }
                    .flatMap { release(from: $0, country: country) }
                    .map { ($0, counts[collectionID] ?? 0) }
            }
            .enumerated()
            .sorted { $0.element.1 != $1.element.1 ? $0.element.1 > $1.element.1 : $0.offset < $1.offset }
            .map(\.element)
        return SongReleases(ranked: ranked, identifiers: identifiers)
    }

    /// Searches for a song by title and artist, keeping only results with the same title.
    /// Searches by title alone if the artist is credited differently in the store.
    private static func searchSongs(title: String, artist: String?, country: String) async throws -> [Result] {
        let terms = [artist.map { "\(title) \($0)" }, title].compactMap { $0 }
        for term in terms {
            var components = URLComponents(string: "https://itunes.apple.com/search")!
            components.queryItems = [
                URLQueryItem(name: "term", value: term),
                URLQueryItem(name: "entity", value: "song"),
                URLQueryItem(name: "country", value: country),
                URLQueryItem(name: "limit", value: "50")
            ]
            let matching = try await fetch(components.url!).results.filter { result in
                result.wrapperType == "track" &&
                    result.trackName?.compare(title, options: [.caseInsensitive, .diacriticInsensitive,
                                                               .widthInsensitive]) == .orderedSame
            }
            if !matching.isEmpty {
                return matching
            }
        }
        return []
    }

    private static func lookup(ids: [String], country: String) async throws -> [Result] {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")!
        components.queryItems = [
            URLQueryItem(name: "id", value: ids.joined(separator: ",")),
            URLQueryItem(name: "country", value: country)
        ]
        return try await fetch(components.url!).results
    }

    private static func fetch(_ url: URL) async throws -> Response {
        try JSONDecoder().decode(Response.self, from: try await LookupSource.data(from: url))
    }

    private static func release(from result: Result, country: String?) -> OnlineRelease? {
        guard result.wrapperType == "collection", let id = result.collectionId,
              let title = result.collectionName else { return nil }
        return OnlineRelease(id: String(id),
                             source: .iTunes,
                             country: country,
                             title: title,
                             artist: result.collectionArtistName ?? result.artistName ?? "",
                             year: result.releaseDate.map { String($0.prefix(4)) },
                             trackCount: result.trackCount,
                             details: [result.primaryGenreName].compactMap { $0 },
                             thumbnailURL: artworkURL(result.artworkUrl100, size: 200),
                             artworkURL: artworkURL(result.artworkUrl100, size: 1000))
    }

    /// Artwork URLs end with the image size, such as 100x100bb.jpg, which can be swapped for a larger one.
    private static func artworkURL(_ url: String?, size: Int) -> URL? {
        guard let url else { return nil }
        return URL(string: url.replacingOccurrences(of: "100x100bb", with: "\(size)x\(size)bb"))
    }
}
