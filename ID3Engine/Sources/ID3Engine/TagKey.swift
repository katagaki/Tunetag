//
//  TagKey.swift
//  ID3Engine
//

import Foundation

/// TagLib's format-independent property names.
public enum TagKey {
    public static let title = "TITLE"
    public static let artist = "ARTIST"
    public static let album = "ALBUM"
    public static let albumArtist = "ALBUMARTIST"
    public static let date = "DATE"
    public static let trackNumber = "TRACKNUMBER"
    public static let discNumber = "DISCNUMBER"
    public static let genre = "GENRE"
    public static let composer = "COMPOSER"
    public static let grouping = "GROUPING"
    public static let bpm = "BPM"
    public static let compilation = "COMPILATION"
    public static let comment = "COMMENT"
    public static let lyrics = "LYRICS"
    public static let titleSort = "TITLESORT"
    public static let artistSort = "ARTISTSORT"
    public static let albumSort = "ALBUMSORT"
    public static let albumArtistSort = "ALBUMARTISTSORT"
    public static let composerSort = "COMPOSERSORT"
    public static let conductor = "CONDUCTOR"
    public static let publisher = "LABEL"
    public static let copyright = "COPYRIGHT"
    public static let encodedBy = "ENCODEDBY"
    public static let isrc = "ISRC"
    public static let musicBrainzReleaseID = "MUSICBRAINZ_ALBUMID"
    public static let musicBrainzRecordingID = "MUSICBRAINZ_TRACKID"
    public static let replayGainTrackGain = "REPLAYGAIN_TRACK_GAIN"
    public static let replayGainTrackPeak = "REPLAYGAIN_TRACK_PEAK"
    public static let replayGainAlbumGain = "REPLAYGAIN_ALBUM_GAIN"
    public static let replayGainAlbumPeak = "REPLAYGAIN_ALBUM_PEAK"

    /// Separate total fields used by Vorbis comments, in order of preference.
    public static let trackTotals = ["TRACKTOTAL", "TOTALTRACKS"]
    public static let discTotals = ["DISCTOTAL", "TOTALDISCS"]
}
