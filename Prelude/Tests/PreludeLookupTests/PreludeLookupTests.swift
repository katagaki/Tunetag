//
//  PreludeLookupTests.swift
//  PreludeLookup
//

import Foundation
import Prelude
import XCTest
@testable import PreludeLookup

final class PreludeLookupTests: XCTestCase {

    static let tracks = [
        OnlineTrack(title: "One", artist: "A", number: 1, disc: 1),
        OnlineTrack(title: "Two", artist: "A", number: 2, disc: 1),
        OnlineTrack(title: "Three", artist: "B", number: 3, disc: 1),
        OnlineTrack(title: "Disc Two One", artist: "C", number: 1, disc: 2, recordingID: "recording"),
        OnlineTrack(title: "Disc Two Two", artist: "C", number: 2, disc: 2)
    ]

    static let detail = OnlineReleaseDetail(
        release: OnlineRelease(id: "release", source: .musicBrainz, title: "Album", artist: "Album Artist",
                               year: "2021", artworkURL: URL(string: "https://example.com/cover.jpg")),
        tracks: tracks,
        genre: "Soundtrack",
        publisher: "Label")

    var workDirectory: URL!

    override func setUpWithError() throws {
        workDirectory = FileManager.default.temporaryDirectory
            .appending(path: "PreludeLookupTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: workDirectory)
    }

    /// Copies one of Prelude's test fixtures so tests never modify the originals.
    func copyOfFixture(_ name: String) throws -> String {
        let source = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appending(path: "../PreludeTests/Fixtures/\(name)")
        let destination = workDirectory.appending(path: name)
        try FileManager.default.copyItem(at: source, to: destination)
        return destination.path
    }

    func testMatchesByDiscAndTrackNumber() {
        let files = [
            LookupMatch(path: "/b.m4a", currentTrack: 2, currentDisc: 2),
            LookupMatch(path: "/a.m4a", currentTrack: 3)
        ]
        let matches = LookupMatch.matched(files, to: Self.tracks)
        XCTAssertEqual(matches.map(\.trackID), ["2-2", "1-3"])
    }

    func testMatchesFilesWithoutNumbersInOrder() {
        let files = LookupMatch.sorted([
            LookupMatch(path: "/Track 10.m4a"),
            LookupMatch(path: "/Track 2.m4a"),
            LookupMatch(path: "/Track 1.m4a")
        ])
        XCTAssertEqual(files.map(\.filename), ["Track 1.m4a", "Track 2.m4a", "Track 10.m4a"])
        let matches = LookupMatch.matched(files, to: Self.tracks)
        XCTAssertEqual(matches.map(\.trackID), ["1-1", "1-2", "1-3"])
    }

    func testGivesUnmatchedNumbersTheRemainingTracks() {
        let files = [
            LookupMatch(path: "/a.m4a", currentTrack: 1),
            LookupMatch(path: "/b.m4a", currentTrack: 8, currentDisc: 4),
            LookupMatch(path: "/c.m4a", currentTrack: 1)
        ]
        let matches = LookupMatch.matched(files, to: Self.tracks)
        XCTAssertEqual(matches.map(\.trackID), ["1-1", "1-2", "1-3"])
    }

    func testLeavesExtraFilesUnmatched() {
        let files = (1...6).map { LookupMatch(path: "/\($0).m4a", currentTrack: $0) }
        let matches = LookupMatch.matched(files, to: Array(Self.tracks.prefix(2)))
        XCTAssertEqual(matches.compactMap(\.trackID), ["1-1", "1-2"])
    }

    func testMatchesRecognizedFilesToTheirExactTracks() {
        var tracks = Self.tracks
        tracks[2].storeID = "123"
        let files = [
            LookupMatch(path: "/recognized.m4a", currentTrack: 1),
            LookupMatch(path: "/numbered.m4a", currentTrack: 1, currentDisc: 2)
        ]
        let identifiers = ["/recognized.m4a": Set(["123"]), "/numbered.m4a": Set(["recording"])]
        let matches = LookupMatch.matched(files, to: tracks, identifiers: identifiers)
        XCTAssertEqual(matches.map(\.trackID), ["1-3", "2-1"])
    }

    func testSpreadsRecognitionAcrossFiles() {
        XCTAssertEqual(AudioRecognizer.spread(Array(1...10), count: 3), [1, 5, 10])
        XCTAssertEqual(AudioRecognizer.spread([1, 2], count: 3), [1, 2])
    }

    func testPicksBestMatchOnlyWhenItHasTheMostSongs() {
        let first = OnlineRelease(id: "1", source: .iTunes, title: "Album", artist: "")
        let second = OnlineRelease(id: "2", source: .iTunes, title: "Compilation", artist: "")
        XCTAssertEqual(AutomaticLookup.bestMatch([(first, 3), (second, 1)])?.id, "1")
        XCTAssertNil(AutomaticLookup.bestMatch([(first, 2), (second, 2)]))
        XCTAssertEqual(AutomaticLookup.bestMatch([(second, 1)])?.id, "2")
    }

    func testBuildsTagFromChosenFields() {
        let track = Self.tracks[3]
        let tag = Self.detail.tag(for: track, fields: [.title, .track, .disc])
        XCTAssertEqual(tag.title, "Disc Two One")
        XCTAssertEqual(tag.track, "1")
        XCTAssertEqual(tag.trackTotal, "2")
        XCTAssertEqual(tag.discNumber, "2")
        XCTAssertEqual(tag.discTotal, "2")
        XCTAssertNil(tag.artist)
        XCTAssertNil(tag.album)
        XCTAssertNil(tag.genre)
    }

    func testAppliesToFile() throws {
        for name in ["m4a_aac.m4a", "flac.flac", "mp3_v24.mp3"] {
            let path = try copyOfFixture(name)
            let track = Self.tracks[3]
            let fields = LookupField.defaultFields.subtracting([.year])
            XCTAssertTrue(Self.detail.apply(track, fields: fields, albumArt: nil, toFileAt: path), name)

            let file = try XCTUnwrap(TagLibFile(path: path), name)
            let snapshot = TagSnapshot(file)
            XCTAssertEqual(snapshot.title, "Disc Two One", name)
            XCTAssertEqual(snapshot.artist, "C", name)
            XCTAssertEqual(snapshot.album, "Album", name)
            XCTAssertEqual(snapshot.albumArtist, "Album Artist", name)
            XCTAssertEqual(snapshot.track, 1, name)
            XCTAssertEqual(snapshot.trackTotal, 2, name)
            XCTAssertEqual(snapshot.discNumber, 2, name)
            XCTAssertEqual(snapshot.discTotal, 2, name)
            XCTAssertEqual(snapshot.genre, "Soundtrack", name)
            XCTAssertEqual(snapshot.year, "1999", "Fields that aren't chosen are kept in \(name)")
            XCTAssertEqual(snapshot.musicBrainzReleaseID, "release", name)
            XCTAssertEqual(snapshot.musicBrainzRecordingID, "recording", name)
        }
    }
}
