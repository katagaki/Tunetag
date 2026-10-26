//
//  LookupSource.swift
//  Tunetag
//

import Foundation

/// An online database that album tags can be looked up from.
enum LookupSource: String, CaseIterable, Identifiable, Sendable {
    case iTunes
    case musicBrainz

    var id: String {
        rawValue
    }

    /// The source's brand name, which isn't translated.
    var name: String {
        switch self {
        case .iTunes: return "iTunes"
        case .musicBrainz: return "MusicBrainz"
        }
    }

    func search(artist: String, album: String) async throws -> [OnlineRelease] {
        let results = try await searchSource(artist: artist, album: album)
        // The artist may be a track artist on a compilation, which won't match the album's artist
        if results.isEmpty && !artist.isEmpty && !album.isEmpty {
            return try await searchSource(artist: "", album: album)
        }
        return results
    }

    private func searchSource(artist: String, album: String) async throws -> [OnlineRelease] {
        switch self {
        case .iTunes: return try await ITunesLookup.search(artist: artist, album: album)
        case .musicBrainz: return try await MusicBrainzLookup.search(artist: artist, album: album)
        }
    }

    func detail(for release: OnlineRelease) async throws -> OnlineReleaseDetail {
        switch self {
        case .iTunes: return try await ITunesLookup.detail(for: release)
        case .musicBrainz: return try await MusicBrainzLookup.detail(for: release)
        }
    }

    /// Downloads data, failing on anything other than a successful response.
    static func data(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        // MusicBrainz asks every client to identify itself
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        request.setValue("Tunetag/\(version) ( https://github.com/katagaki/Tunetag )",
                         forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw LookupError.badResponse
        }
        return data
    }
}
