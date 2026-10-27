//
//  AudioRecognizer.swift
//  PreludeLookup
//

import AVFoundation
import Foundation
import OSLog
import ShazamKit

/// A song recognized from a file's audio.
public struct RecognizedSong: Sendable {
    public var path: String
    public var title: String?
    public var artist: String?
    public var appleMusicID: String?
    public var isrc: String?
}

/// Recognizes songs with ShazamKit. Apps using it need the ShazamKit App Service enabled for their identifier.
public enum AudioRecognizer {

    private static let logger = Logger(subsystem: "PreludeLookup", category: "AudioRecognizer")

    /// The length of audio to recognize, which is enough for Shazam without reading the whole file.
    static let clipDuration: Double = 12.0

    /// Recognizes the song in a file, or returns nil if it isn't in Shazam's catalog or can't be read.
    public static func recognize(fileAt path: String) async -> RecognizedSong? {
        do {
            let asset = AVURLAsset(url: URL(filePath: path))
            let duration = try await asset.load(.duration).seconds
            guard duration.isFinite, duration > 0 else { return nil }

            // Skip intros, which are often quiet or shared between versions of a song
            let start = max(0.0, min(duration * 0.3, duration - clipDuration))
            let length = min(clipDuration, duration)
            let clip = AVMutableComposition()
            try await clip.insertTimeRange(CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600),
                                                       duration: CMTime(seconds: length, preferredTimescale: 600)),
                                           of: asset, at: .zero)
            let signature = try await SHSignatureGenerator.signature(from: clip)

            guard case .match(let match) = await SHSession().result(from: signature),
                  let item = match.mediaItems.first else {
                logger.debug("No match for \(path, privacy: .private)")
                return nil
            }
            logger.debug("""
                Recognized \(item.title ?? "", privacy: .public) by \(item.artist ?? "", privacy: .public), \
                Apple Music ID \(item.appleMusicID ?? "none", privacy: .public), ISRC \(item.isrc ?? "none", privacy: .public)
                """)
            return RecognizedSong(path: path,
                                  title: item.title,
                                  artist: item.artist,
                                  appleMusicID: item.appleMusicID,
                                  isrc: item.isrc)
        } catch {
            return nil
        }
    }

    /// Recognizes a few of the files, spread across the list, since one album's songs are enough to find it.
    public static func recognize(filesAt paths: [String], limit: Int = 3) async -> [RecognizedSong] {
        let samples = spread(paths, count: limit)
        return await withTaskGroup(of: RecognizedSong?.self) { group in
            for path in samples {
                group.addTask { await recognize(fileAt: path) }
            }
            var songs: [RecognizedSong] = []
            for await song in group {
                if let song {
                    songs.append(song)
                }
            }
            // Keep the files' order so the first song is the most representative
            return songs.sorted { lhs, rhs in
                (samples.firstIndex(of: lhs.path) ?? 0) < (samples.firstIndex(of: rhs.path) ?? 0)
            }
        }
    }

    /// Picks evenly spaced items, such as the first, middle, and last.
    static func spread<T>(_ items: [T], count: Int) -> [T] {
        guard items.count > count, count > 1 else { return Array(items.prefix(count)) }
        return (0..<count).map { items[$0 * (items.count - 1) / (count - 1)] }
    }
}
