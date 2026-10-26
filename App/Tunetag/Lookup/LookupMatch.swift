//
//  LookupMatch.swift
//  Tunetag
//

import Foundation
import Prelude

/// A selected file and the online track whose tags it will receive.
struct LookupMatch: Identifiable, Sendable {
    var file: FSFile
    var currentTitle: String?
    var currentTrack: Int?
    var currentDisc: Int?
    var trackID: OnlineTrack.ID?

    var id: String {
        file.id
    }

    /// Reads each file's own title and numbers, sorted into album order.
    static func read(_ files: [FSFile]) async -> [LookupMatch] {
        await Task.detached(priority: .userInitiated) {
            files.map { file in
                let snapshot = TagLibFile(path: file.path).map { TagSnapshot($0) }
                return LookupMatch(file: file,
                                   currentTitle: snapshot?.title,
                                   currentTrack: snapshot?.track,
                                   currentDisc: snapshot?.discNumber)
            }
            .sorted { lhs, rhs in
                let lhsOrder = (lhs.currentDisc ?? 1, lhs.currentTrack ?? Int.max)
                let rhsOrder = (rhs.currentDisc ?? 1, rhs.currentTrack ?? Int.max)
                if lhsOrder != rhsOrder {
                    return lhsOrder < rhsOrder
                }
                return lhs.file.name.localizedStandardCompare(rhs.file.name) == .orderedAscending
            }
        }.value
    }

    /// Matches files to tracks by their disc and track numbers, then gives the remaining files
    /// the remaining tracks in album order.
    static func matched(_ matches: [LookupMatch], to tracks: [OnlineTrack]) -> [LookupMatch] {
        var matches = matches
        var usedTrackIDs = Set<OnlineTrack.ID>()
        for index in matches.indices {
            matches[index].trackID = nil
            guard let number = matches[index].currentTrack else { continue }
            let disc = matches[index].currentDisc ?? 1
            if let track = tracks.first(where: { $0.number == number && $0.disc == disc }),
               !usedTrackIDs.contains(track.id) {
                matches[index].trackID = track.id
                usedTrackIDs.insert(track.id)
            }
        }
        var remainingTracks = tracks.filter { !usedTrackIDs.contains($0.id) }.makeIterator()
        for index in matches.indices where matches[index].trackID == nil {
            matches[index].trackID = remainingTracks.next()?.id
        }
        return matches
    }
}

/// Fields that an online lookup can overwrite.
enum LookupField: String, CaseIterable, Identifiable, Sendable {
    case title
    case artist
    case album
    case albumArtist
    case year
    case track
    case disc
    case genre
    case albumArt
    case publisher
    case copyright
    case musicBrainzIDs

    var id: String {
        rawValue
    }

    var name: LocalizedStringResource {
        switch self {
        case .title: return "Tag.Title"
        case .artist: return "Tag.Artist"
        case .album: return "Tag.Album"
        case .albumArtist: return "Tag.AlbumArtist"
        case .year: return "Tag.Year"
        case .track: return "Tag.Track"
        case .disc: return "Tag.Disc"
        case .genre: return "Tag.Genre"
        case .albumArt: return "OnlineLookup.AlbumArt"
        case .publisher: return "Tag.Publisher"
        case .copyright: return "Tag.Copyright"
        case .musicBrainzIDs: return "OnlineLookup.MusicBrainzIDs"
        }
    }

    /// Whether the release has a value for the field.
    func isAvailable(in detail: OnlineReleaseDetail) -> Bool {
        switch self {
        case .genre: return detail.genre != nil
        case .albumArt: return detail.release.artworkURL != nil
        case .publisher: return detail.publisher != nil
        case .copyright: return detail.copyright != nil
        case .musicBrainzIDs: return detail.release.source == .musicBrainz
        default: return true
        }
    }

    /// Copyright and label values are often missing from or worded differently by the source,
    /// so they are only written when chosen.
    static let defaultFields: Set<LookupField> = Set(allCases).subtracting([.publisher, .copyright])
}

extension OnlineReleaseDetail {

    /// Writes the chosen fields of a track to a file. Fields that aren't chosen are kept.
    func apply(_ track: OnlineTrack,
               fields: Set<LookupField>,
               albumArt: Data?,
               to file: FSFile) -> Bool {
        guard let tagFile = TagLibFile(path: file.path) else { return false }
        var tag = Tag()
        func set(_ field: LookupField, _ keyPath: WritableKeyPath<Tag, String?>, _ value: String?) {
            if fields.contains(field) {
                tag[keyPath: keyPath] = value
            }
        }
        set(.title, \.title, track.title)
        set(.artist, \.artist, track.artist)
        set(.album, \.album, release.title)
        set(.albumArtist, \.albumArtist, release.artist)
        set(.year, \.year, release.year)
        set(.track, \.track, String(track.number))
        set(.track, \.trackTotal, String(trackTotal(onDisc: track.disc)))
        set(.disc, \.discNumber, String(track.disc))
        set(.disc, \.discTotal, String(discTotal))
        set(.genre, \.genre, genre)
        set(.publisher, \.publisher, publisher)
        set(.copyright, \.copyright, copyright)
        TagWriter.apply(tag, to: tagFile, albumArt: fields.contains(.albumArt) ? albumArt : nil)
        if fields.contains(.musicBrainzIDs), release.source == .musicBrainz {
            tagFile.setValues([release.id], forProperty: TagKey.musicBrainzReleaseID)
            if let recordingID = track.recordingID {
                tagFile.setValues([recordingID], forProperty: TagKey.musicBrainzRecordingID)
            }
        }
        return tagFile.save()
    }
}
