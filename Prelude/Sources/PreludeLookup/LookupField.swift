//
//  LookupField.swift
//  PreludeLookup
//

import Foundation
import Prelude

/// Fields that an online lookup can overwrite.
public enum LookupField: String, CaseIterable, Identifiable, Sendable {
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

    public var id: String {
        rawValue
    }

    /// Whether the release has a value for the field.
    public func isAvailable(in detail: OnlineReleaseDetail) -> Bool {
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
    public static let defaultFields: Set<LookupField> = Set(allCases).subtracting([.publisher, .copyright])
}

extension OnlineReleaseDetail {

    /// The tag values for the chosen fields of a track. Fields that aren't chosen are nil, so they are kept.
    public func tag(for track: OnlineTrack, fields: Set<LookupField>) -> Tag {
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
        return tag
    }

    /// Writes the chosen fields of a track to a file and saves it.
    /// - Parameter albumArt: Image data for the front cover, written when album art is chosen.
    public func apply(_ track: OnlineTrack,
                      fields: Set<LookupField>,
                      albumArt: Data?,
                      toFileAt path: String) -> Bool {
        guard let tagFile = TagLibFile(path: path) else { return false }
        TagWriter.apply(tag(for: track, fields: fields), to: tagFile,
                        albumArt: fields.contains(.albumArt) ? albumArt : nil)
        if fields.contains(.musicBrainzIDs), release.source == .musicBrainz {
            tagFile.setValues([release.id], forProperty: TagKey.musicBrainzReleaseID)
            if let recordingID = track.recordingID {
                tagFile.setValues([recordingID], forProperty: TagKey.musicBrainzRecordingID)
            }
        }
        return tagFile.save()
    }
}
