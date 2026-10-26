//
//  MusicBrainzLookup.swift
//  Tunetag
//

import Foundation

/// Looks up releases on MusicBrainz, with cover art from the Cover Art Archive.
enum MusicBrainzLookup {

    private struct SearchResponse: Decodable {
        var releases: [Release]
    }

    private struct Release: Decodable {
        var id: String
        var title: String
        var date: String?
        var country: String?
        var disambiguation: String?
        var artistCredit: [ArtistCredit]?
        var trackCount: Int?
        var media: [Medium]?
        var labelInfo: [LabelInfo]?
        var genres: [Genre]?
        var coverArtArchive: CoverArtArchive?
    }

    private struct ArtistCredit: Decodable {
        var name: String
        var joinphrase: String?
    }

    private struct Medium: Decodable {
        var position: Int?
        var format: String?
        var tracks: [Track]?
    }

    private struct Track: Decodable {
        var position: Int
        var title: String
        var length: Double?
        var artistCredit: [ArtistCredit]?
        var recording: Recording?
    }

    private struct Recording: Decodable {
        var id: String
    }

    private struct LabelInfo: Decodable {
        var label: Label?
    }

    private struct Label: Decodable {
        var name: String
    }

    private struct Genre: Decodable {
        var name: String
        var count: Int?
    }

    private struct CoverArtArchive: Decodable {
        var front: Bool
    }

    /// MusicBrainz uses kebab-case keys, such as artist-credit.
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .custom { codingPath in
            let key = codingPath.last!.stringValue
            let parts = key.split(separator: "-")
            let camelCased = parts.enumerated()
                .map { $0.offset == 0 ? String($0.element) : $0.element.capitalized }
                .joined()
            return AnyCodingKey(stringValue: camelCased)
        }
        return decoder
    }()

    private struct AnyCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
    }

    static func search(artist: String, album: String) async throws -> [OnlineRelease] {
        let query = [("artist", artist), ("release", album)]
            .filter { !$0.1.isEmpty }
            .map { "\($0.0):(\(escaped($0.1)))" }
            .joined(separator: " AND ")
        var components = URLComponents(string: "https://musicbrainz.org/ws/2/release")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "limit", value: "50")
        ]
        let data = try await LookupSource.data(from: components.url!)
        let response = try decoder.decode(SearchResponse.self, from: data)
        return response.releases.map { release(from: $0) }
    }

    static func detail(for release: OnlineRelease) async throws -> OnlineReleaseDetail {
        var components = URLComponents(string: "https://musicbrainz.org/ws/2/release/\(release.id)")!
        components.queryItems = [
            URLQueryItem(name: "inc", value: "recordings+artist-credits+labels+genres"),
            URLQueryItem(name: "fmt", value: "json")
        ]
        let data = try await LookupSource.data(from: components.url!)
        let response = try decoder.decode(Release.self, from: data)
        let albumArtist = artistName(response.artistCredit) ?? release.artist
        let tracks = (response.media ?? []).enumerated().flatMap { index, medium in
            (medium.tracks ?? []).map { track in
                OnlineTrack(title: track.title,
                            artist: artistName(track.artistCredit) ?? albumArtist,
                            number: track.position,
                            disc: medium.position ?? index + 1,
                            duration: track.length.map { $0 / 1000.0 },
                            recordingID: track.recording?.id)
            }
        }
        var detailedRelease = self.release(from: response)
        if response.coverArtArchive?.front == false {
            detailedRelease.thumbnailURL = nil
            detailedRelease.artworkURL = nil
        }
        let genre = response.genres?.max { ($0.count ?? 0) < ($1.count ?? 0) }?.name.capitalized
        return OnlineReleaseDetail(release: detailedRelease,
                                   tracks: tracks,
                                   genre: genre,
                                   publisher: response.labelInfo?.lazy.compactMap { $0.label?.name }.first)
    }

    private static func release(from release: Release) -> OnlineRelease {
        let formats = (release.media ?? []).compactMap(\.format)
        let format: String? = Set(formats).count == 1 && formats.count > 1
            ? "\(formats.count)×\(formats[0])"
            : formats.isEmpty ? nil : formats.joined(separator: " + ")
        let coverArt = "https://coverartarchive.org/release/\(release.id)"
        return OnlineRelease(id: release.id,
                             source: .musicBrainz,
                             title: release.title,
                             artist: artistName(release.artistCredit) ?? "",
                             year: release.date.flatMap { $0.count >= 4 ? String($0.prefix(4)) : nil },
                             trackCount: release.trackCount,
                             details: [format, release.country, release.disambiguation]
                                .compactMap { $0 }.filter { !$0.isEmpty },
                             thumbnailURL: URL(string: "\(coverArt)/front-250"),
                             artworkURL: URL(string: "\(coverArt)/front-1200"))
    }

    /// Joins an artist credit, such as "Artist A feat. Artist B".
    private static func artistName(_ credits: [ArtistCredit]?) -> String? {
        guard let credits, !credits.isEmpty else { return nil }
        return credits.map { $0.name + ($0.joinphrase ?? "") }.joined()
    }

    /// Escapes characters that have a meaning in MusicBrainz's Lucene search syntax.
    private static func escaped(_ text: String) -> String {
        let special = Set("+-&|!(){}[]^\"~*?:\\/")
        return String(text.flatMap { special.contains($0) ? ["\\", $0] : [$0] })
    }
}
