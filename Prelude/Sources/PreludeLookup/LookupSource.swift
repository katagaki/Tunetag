//
//  LookupSource.swift
//  PreludeLookup
//

import Foundation

/// An online database that album tags can be looked up from.
public enum LookupSource: String, CaseIterable, Identifiable, Sendable {
    case iTunes
    case musicBrainz

    public var id: String {
        rawValue
    }

    /// The source's brand name, which isn't translated.
    public var name: String {
        switch self {
        case .iTunes: return "iTunes"
        case .musicBrainz: return "MusicBrainz"
        }
    }

    /// Searches for albums by artist and album name.
    /// - Parameter country: The store to search for sources with regional stores, as a two-letter region code.
    ///   Defaults to the user's region.
    public func search(artist: String,
                       album: String,
                       country: String = LookupSource.defaultCountry) async throws -> [OnlineRelease] {
        let results = try await searchSource(artist: artist, album: album, country: country)
        // The artist may be a track artist on a compilation, which won't match the album's artist
        if results.isEmpty && !artist.isEmpty && !album.isEmpty {
            return try await searchSource(artist: "", album: album, country: country)
        }
        return results
    }

    /// Loads a release's tracks and album-level values.
    public func detail(for release: OnlineRelease) async throws -> OnlineReleaseDetail {
        switch self {
        case .iTunes: return try await ITunesLookup.detail(for: release)
        case .musicBrainz: return try await MusicBrainzLookup.detail(for: release)
        }
    }

    /// The user's region, so that albums are found in the store they would buy them from.
    public static var defaultCountry: String {
        Locale.current.region?.identifier ?? "US"
    }

    private func searchSource(artist: String, album: String, country: String) async throws -> [OnlineRelease] {
        switch self {
        case .iTunes: return try await ITunesLookup.search(artist: artist, album: album, country: country)
        case .musicBrainz: return try await MusicBrainzLookup.search(artist: artist, album: album)
        }
    }

    /// Downloads data, failing on anything other than a successful response.
    public static func data(from url: URL) async throws -> Data {
        if url.host() == "musicbrainz.org" {
            await musicBrainzThrottle.wait()
        }
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw LookupError.badResponse
        }
        return data
    }

    /// MusicBrainz allows one request per second from each client.
    private static let musicBrainzThrottle = RequestThrottle(interval: 1.0)

    /// MusicBrainz asks every client to identify itself with its name, version, and contact details.
    private static var userAgent: String {
        let info = Bundle.main.infoDictionary
        let name = info?["CFBundleName"] as? String ?? "Prelude"
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "\(name)/\(version) ( https://github.com/katagaki/Tunetag )"
    }
}

/// Spaces out requests to a service with a rate limit.
actor RequestThrottle {

    let interval: TimeInterval
    private var nextRequest = Date.distantPast

    init(interval: TimeInterval) {
        self.interval = interval
    }

    func wait() async {
        let now = Date()
        let start = max(now, nextRequest)
        nextRequest = start.addingTimeInterval(interval)
        let delay = start.timeIntervalSince(now)
        if delay > 0 {
            try? await Task.sleep(for: .seconds(delay))
        }
    }
}
