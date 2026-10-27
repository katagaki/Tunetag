//
//  LookupMatch.swift
//  PreludeLookup
//

import Foundation
import Prelude

/// A file and the online track whose tags it will receive.
public struct LookupMatch: Identifiable, Sendable {
    public var path: String
    public var currentTitle: String?
    public var currentTrack: Int?
    public var currentDisc: Int?
    public var trackID: OnlineTrack.ID?

    public var id: String {
        path
    }

    public var filename: String {
        (path as NSString).lastPathComponent
    }

    public init(path: String,
                currentTitle: String? = nil,
                currentTrack: Int? = nil,
                currentDisc: Int? = nil,
                trackID: OnlineTrack.ID? = nil) {
        self.path = path
        self.currentTitle = currentTitle
        self.currentTrack = currentTrack
        self.currentDisc = currentDisc
        self.trackID = trackID
    }

    /// Reads each file's own title and numbers, sorted into album order.
    public static func read(paths: [String]) async -> [LookupMatch] {
        await Task.detached(priority: .userInitiated) {
            sorted(paths.map { path in
                let snapshot = TagLibFile(path: path).map { TagSnapshot($0) }
                return LookupMatch(path: path,
                                   currentTitle: snapshot?.title,
                                   currentTrack: snapshot?.track,
                                   currentDisc: snapshot?.discNumber)
            })
        }.value
    }

    /// Sorts by disc and track number, then by filename for files without numbers.
    public static func sorted(_ matches: [LookupMatch]) -> [LookupMatch] {
        matches.sorted { lhs, rhs in
            let lhsOrder = (lhs.currentDisc ?? 1, lhs.currentTrack ?? Int.max)
            let rhsOrder = (rhs.currentDisc ?? 1, rhs.currentTrack ?? Int.max)
            if lhsOrder != rhsOrder {
                return lhsOrder < rhsOrder
            }
            return lhs.filename.localizedStandardCompare(rhs.filename) == .orderedAscending
        }
    }

    /// Matches recognized files to their exact tracks, then other files by their disc and track numbers,
    /// then gives the remaining files the remaining tracks in album order.
    /// - Parameter identifiers: Store or recording IDs recognized for each file, by path.
    public static func matched(_ matches: [LookupMatch],
                               to tracks: [OnlineTrack],
                               identifiers: [String: Set<String>] = [:]) -> [LookupMatch] {
        var matches = matches
        var usedTrackIDs = Set<OnlineTrack.ID>()
        for index in matches.indices {
            matches[index].trackID = nil
            guard let fileIdentifiers = identifiers[matches[index].path] else { continue }
            if let track = tracks.first(where: { track in
                !usedTrackIDs.contains(track.id) &&
                    [track.storeID, track.recordingID].contains { $0.map(fileIdentifiers.contains) ?? false }
            }) {
                matches[index].trackID = track.id
                usedTrackIDs.insert(track.id)
            }
        }
        for index in matches.indices where matches[index].trackID == nil {
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
