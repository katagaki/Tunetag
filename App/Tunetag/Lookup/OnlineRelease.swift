//
//  OnlineRelease.swift
//  Tunetag
//

import Foundation

/// An album found in an online source's search results.
struct OnlineRelease: Identifiable, Hashable, Sendable {
    var id: String
    var source: LookupSource
    var title: String
    var artist: String
    var year: String?
    var trackCount: Int?
    /// Extra details that tell similar releases apart, such as the format and country.
    var details: [String] = []
    var thumbnailURL: URL?
    var artworkURL: URL?
}

/// A track on an online release.
struct OnlineTrack: Identifiable, Hashable, Sendable {
    var title: String
    var artist: String
    var number: Int
    var disc: Int
    var duration: TimeInterval?
    var recordingID: String?

    var id: String {
        "\(disc)-\(number)"
    }
}

/// An online release with its tracks and album-level values.
struct OnlineReleaseDetail: Sendable {
    var release: OnlineRelease
    var tracks: [OnlineTrack]
    var genre: String?
    var copyright: String?
    var publisher: String?

    var discTotal: Int {
        tracks.map(\.disc).max() ?? 1
    }

    func trackTotal(onDisc disc: Int) -> Int {
        tracks.filter { $0.disc == disc }.map(\.number).max() ?? 0
    }
}

enum LookupError: Error {
    case badResponse
}
