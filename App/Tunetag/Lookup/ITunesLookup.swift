//
//  ITunesLookup.swift
//  Tunetag
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

    /// Searches the store of the user's region, so that titles appear as they are sold locally.
    private static var country: String {
        Locale.current.region?.identifier ?? "US"
    }

    static func search(artist: String, album: String) async throws -> [OnlineRelease] {
        let term = [artist, album].filter { !$0.isEmpty }.joined(separator: " ")
        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "entity", value: "album"),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "limit", value: "50")
        ]
        let response = try await fetch(components.url!)
        return response.results.compactMap { release(from: $0) }
    }

    static func detail(for release: OnlineRelease) async throws -> OnlineReleaseDetail {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")!
        components.queryItems = [
            URLQueryItem(name: "id", value: release.id),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "country", value: country)
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
                                   duration: result.trackTimeMillis.map { $0 / 1000.0 })
            }
            .sorted { ($0.disc, $0.number) < ($1.disc, $1.number) }
        return OnlineReleaseDetail(release: self.release(from: collection) ?? release,
                                   tracks: tracks,
                                   genre: collection.primaryGenreName,
                                   copyright: collection.copyright)
    }

    private static func fetch(_ url: URL) async throws -> Response {
        try JSONDecoder().decode(Response.self, from: try await LookupSource.data(from: url))
    }

    private static func release(from result: Result) -> OnlineRelease? {
        guard result.wrapperType == "collection", let id = result.collectionId,
              let title = result.collectionName else { return nil }
        return OnlineRelease(id: String(id),
                             source: .iTunes,
                             title: title,
                             artist: result.artistName ?? "",
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
