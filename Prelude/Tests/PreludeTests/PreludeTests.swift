//
//  PreludeTests.swift
//  Prelude
//

import Foundation
import XCTest
@testable import Prelude

final class PreludeTests: XCTestCase {

    static let formats = ["mp3_v23_v1.mp3", "mp3_v24.mp3", "m4a_aac.m4a", "m4a_alac.m4a", "flac.flac",
                          "vorbis.ogg", "opus.opus", "wav.wav", "aiff.aiff"]

    var workDirectory: URL!

    override func setUpWithError() throws {
        workDirectory = FileManager.default.temporaryDirectory
            .appending(path: "PreludeTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: workDirectory)
    }

    /// Copies a fixture so tests never modify the originals.
    func copyOfFixture(_ name: String) throws -> String {
        let source = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: nil,
                                                     subdirectory: "Fixtures"))
        let destination = workDirectory.appending(path: name)
        try FileManager.default.copyItem(at: source, to: destination)
        return destination.path
    }

    func coverData() throws -> Data {
        try Data(contentsOf: XCTUnwrap(Bundle.module.url(forResource: "cover", withExtension: "png",
                                                         subdirectory: "Fixtures")))
    }

    func testReadsExistingTags() throws {
        for name in Self.formats {
            let snapshot = TagSnapshot(try XCTUnwrap(TagLibFile(path: copyOfFixture(name)), name))
            XCTAssertEqual(snapshot.title, "Original Title", name)
            XCTAssertEqual(snapshot.year, "1999", name)
            XCTAssertEqual(snapshot.track, 5, name)
            XCTAssertEqual(snapshot.trackTotal, 12, name)
        }
    }

    func testRoundTripsEveryField() throws {
        let cover = try coverData()
        for name in Self.formats {
            let path = try copyOfFixture(name)
            let before = TagSnapshot(try XCTUnwrap(TagLibFile(path: path), name))

            var tag = Tag()
            tag.title = "%TOKEN% ✓ 日本語"
            tag.artist = "Rick Astley"
            tag.year = "2024-05"
            tag.track = "6"
            tag.discTotal = "3"
            tag.grouping = "80s"
            tag.bpm = "113"
            tag.isCompilation = true
            tag.comment = "Playlist: Favourites"
            tag.lyrics = "Line one\nLine two"
            tag.artistSortOrder = "Astley, Rick"
            tag.conductor = "Conductor Name"
            tag.publisher = "RCA"
            tag.copyright = "© 1987 RCA"
            tag.encodedBy = "Tunetag"
            let file = try XCTUnwrap(TagLibFile(path: path))
            TagWriter.apply(tag, to: file, albumArt: cover) {
                $0.replacingOccurrences(of: "%TOKEN%", with: "Never Gonna Give You Up")
            }
            XCTAssertTrue(file.save(), name)
            XCTAssertEqual(file.unsupportedProperties, [], name)

            let after = TagSnapshot(try XCTUnwrap(TagLibFile(path: path)))
            XCTAssertEqual(after.title, "Never Gonna Give You Up ✓ 日本語", name)
            XCTAssertEqual(after.artist, "Rick Astley", name)
            XCTAssertEqual(after.album, before.album, "Untouched fields are kept: \(name)")
            XCTAssertEqual(after.year, "2024-05", "Partial dates are kept: \(name)")
            XCTAssertEqual(after.track, 6, name)
            XCTAssertEqual(after.trackTotal, 12, "Track total is kept when only the number changes: \(name)")
            XCTAssertEqual(after.discNumber, before.discNumber, "Disc number is kept: \(name)")
            XCTAssertEqual(after.discTotal, 3, name)
            XCTAssertEqual(after.grouping, "80s", name)
            XCTAssertEqual(after.bpm, 113, name)
            XCTAssertEqual(after.isCompilation, true, name)
            XCTAssertEqual(after.comment, "Playlist: Favourites", name)
            XCTAssertEqual(after.lyrics, "Line one\nLine two", name)
            XCTAssertEqual(after.artistSortOrder, "Astley, Rick", name)
            XCTAssertEqual(after.conductor, "Conductor Name", name)
            XCTAssertEqual(after.publisher, "RCA", name)
            XCTAssertEqual(after.copyright, "© 1987 RCA", name)
            XCTAssertEqual(after.encodedBy, "Tunetag", name)
            XCTAssertEqual(after.albumArt, cover, name)
        }
    }

    func testEmptyValuesRemoveFields() throws {
        for name in Self.formats {
            let path = try copyOfFixture(name)
            var tag = Tag()
            tag.comment = "Comment"
            tag.isCompilation = true
            let setter = try XCTUnwrap(TagLibFile(path: path))
            TagWriter.apply(tag, to: setter)
            XCTAssertTrue(setter.save(), name)

            var clear = Tag()
            clear.comment = ""
            clear.isCompilation = false
            clear.trackTotal = ""
            let clearer = try XCTUnwrap(TagLibFile(path: path))
            TagWriter.apply(clear, to: clearer)
            XCTAssertTrue(clearer.save(), name)

            let properties = try XCTUnwrap(TagLibFile(path: path)).properties
            XCTAssertNil(properties[TagKey.comment], name)
            XCTAssertNil(properties[TagKey.compilation], name)
            XCTAssertEqual(properties[TagKey.title], ["Original Title"], name)
            let snapshot = TagSnapshot(try XCTUnwrap(TagLibFile(path: path)))
            XCTAssertEqual(snapshot.track, 5, name)
            XCTAssertNil(snapshot.trackTotal, name)
        }
    }

    func testFileIsReusableAfterSave() throws {
        for name in Self.formats {
            let path = try copyOfFixture(name)
            let file = try XCTUnwrap(TagLibFile(path: path))
            file.setValues(["First"], forProperty: TagKey.title)
            XCTAssertTrue(file.save(), name)
            XCTAssertEqual(file.properties[TagKey.title], ["First"], name)
            file.setValues(["Second"], forProperty: TagKey.title)
            XCTAssertTrue(file.save(), name)
            XCTAssertEqual(try XCTUnwrap(TagLibFile(path: path)).properties[TagKey.title], ["Second"], name)
        }
    }

    func testCustomFieldsRoundTrip() throws {
        for name in Self.formats {
            let path = try copyOfFixture(name)
            let file = try XCTUnwrap(TagLibFile(path: path))
            file.setValues(["Happy", "Upbeat"], forProperty: "mood")
            XCTAssertTrue(file.save(), name)
            XCTAssertEqual(try XCTUnwrap(TagLibFile(path: path)).properties["MOOD"], ["Happy", "Upbeat"], name)
        }
    }

    func testRemovingFrontCoverKeepsOtherPictures() throws {
        // These fixtures have a front cover followed by a back cover
        for name in ["mp3_v23_v1.mp3", "flac.flac"] {
            let path = try copyOfFixture(name)
            let original = try XCTUnwrap(TagLibFile(path: path))
            let frontCover = try XCTUnwrap(original.frontCover, name)

            let file = try XCTUnwrap(TagLibFile(path: path))
            TagWriter.apply(Tag(), to: file, albumArtRemoved: true)
            XCTAssertTrue(file.save(), name)

            let remaining = try XCTUnwrap(TagLibFile(path: path)).frontCover
            XCTAssertNotNil(remaining, "The back cover is kept: \(name)")
            XCTAssertNotEqual(remaining, frontCover, name)
        }
    }

    func testRemovingFrontCover() throws {
        for name in Self.formats {
            let path = try copyOfFixture(name)
            let adder = try XCTUnwrap(TagLibFile(path: path))
            TagWriter.apply(Tag(), to: adder, albumArt: try coverData())
            XCTAssertTrue(adder.save(), name)

            let remover = try XCTUnwrap(TagLibFile(path: path))
            TagWriter.apply(Tag(), to: remover, albumArtRemoved: true)
            XCTAssertTrue(remover.save(), name)
            let remaining = try XCTUnwrap(TagLibFile(path: path)).frontCover
            XCTAssertNotEqual(remaining, try coverData(), name)
        }
    }

    func testRemoveAllTags() throws {
        for name in Self.formats {
            let path = try copyOfFixture(name)
            XCTAssertTrue(try XCTUnwrap(TagLibFile(path: path)).removeAllTags(), name)
            let file = try XCTUnwrap(TagLibFile(path: path), "File is still readable: \(name)")
            XCTAssertEqual(file.properties, [:], name)
            XCTAssertNil(file.frontCover, name)
        }
    }

    func testMergeKeepsSharedValues() throws {
        let first = try copyOfFixture("mp3_v24.mp3")
        let second = try copyOfFixture("flac.flac")
        let file = try XCTUnwrap(TagLibFile(path: second))
        file.setValues(["Different"], forProperty: TagKey.title)
        XCTAssertTrue(file.save())

        let snapshot = try XCTUnwrap(TagSnapshot.read(paths: [first, second]))
        XCTAssertNil(snapshot.title)
        XCTAssertEqual(snapshot.album, "Orig Album")
        XCTAssertEqual(snapshot.track, 5)
    }

    func testNumberParts() {
        XCTAssertEqual(TagSnapshot.numberParts("5/12").number, 5)
        XCTAssertEqual(TagSnapshot.numberParts("5/12").total, 12)
        XCTAssertEqual(TagSnapshot.numberParts("7").number, 7)
        XCTAssertNil(TagSnapshot.numberParts("7").total)
        XCTAssertNil(TagSnapshot.numberParts("0/3").number)
        XCTAssertEqual(TagSnapshot.numberParts("0/3").total, 3)
        XCTAssertNil(TagSnapshot.numberParts(nil).number)
    }

    func testSupportedExtensions() {
        let extensions = TagLibFile.supportedExtensions()
        for ext in ["mp3", "m4a", "flac", "ogg", "opus", "wav", "aiff"] {
            XCTAssertTrue(extensions.contains(ext), ext)
        }
    }

    func testDisplayNames() {
        XCTAssertEqual(TagKey.displayName(for: "ALBUMARTISTSORT"), "Album Artist Sort")
        XCTAssertEqual(TagKey.displayName(for: "MUSICBRAINZ_ALBUMID"), "MusicBrainz Release ID")
        XCTAssertEqual(TagKey.displayName(for: "COMMENT:ITUNNORM"), "Comment (Itunnorm)")
        XCTAssertEqual(TagKey.displayName(for: "MY_CUSTOM_FIELD"), "My Custom Field")
        XCTAssertEqual(TagKey.key(forDisplayName: "album artist sort"), "ALBUMARTISTSORT")
        XCTAssertEqual(TagKey.key(forDisplayName: " Mood "), "MOOD")
        XCTAssertEqual(TagKey.key(forDisplayName: "My Custom Field"), "MY_CUSTOM_FIELD")
    }
}
