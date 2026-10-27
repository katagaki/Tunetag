//
//  TagKey.swift
//  Prelude
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

    /// Keys that the tag editor's own fields write, so other editors can leave them alone.
    public static let editorKeys: Set<String> = Set([
        title, artist, album, albumArtist, date, trackNumber, discNumber, genre, composer, grouping, bpm,
        compilation, comment, lyrics, titleSort, artistSort, albumSort, albumArtistSort, composerSort,
        conductor, publisher, copyright, encodedBy
    ] + trackTotals + discTotals)

    /// Returns a readable name for a property key, such as "Album Artist Sort" for ALBUMARTISTSORT.
    /// Keys with a description, such as COMMENT:ITUNNORM, include it in parentheses.
    public static func displayName(for key: String) -> String {
        let parts = key.split(separator: ":", maxSplits: 1).map(String.init)
        let base = parts.first ?? key
        let name = displayNames[base.uppercased()] ?? readableName(base)
        guard parts.count > 1, !parts[1].isEmpty else { return name }
        return "\(name) (\(readableName(parts[1])))"
    }

    /// Returns the property key for a name typed by the user, such as ALBUMARTISTSORT for "Album Artist Sort".
    /// Names that aren't standard keys are uppercased with underscores in place of spaces.
    public static func key(forDisplayName name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = displayNames.first(where: { $0.value.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return match.key
        }
        return trimmed.uppercased().replacingOccurrences(of: " ", with: "_")
    }

    private static func readableName(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ").lowercased().capitalized
    }

    private static let displayNames: [String: String] = [
        "TITLE": "Title",
        "SUBTITLE": "Subtitle",
        "ARTIST": "Artist",
        "ARTISTS": "Artists",
        "ALBUM": "Album",
        "ALBUMARTIST": "Album Artist",
        "DATE": "Date",
        "ORIGINALDATE": "Original Date",
        "RELEASEDATE": "Release Date",
        "TRACKNUMBER": "Track Number",
        "TRACKTOTAL": "Track Total",
        "TOTALTRACKS": "Total Tracks",
        "DISCNUMBER": "Disc Number",
        "DISCTOTAL": "Disc Total",
        "TOTALDISCS": "Total Discs",
        "DISCSUBTITLE": "Disc Subtitle",
        "GENRE": "Genre",
        "COMPOSER": "Composer",
        "LYRICIST": "Lyricist",
        "WRITER": "Writer",
        "CONDUCTOR": "Conductor",
        "REMIXER": "Remixer",
        "ARRANGER": "Arranger",
        "ENGINEER": "Engineer",
        "PRODUCER": "Producer",
        "DJMIXER": "DJ Mixer",
        "MIXER": "Mixer",
        "PERFORMER": "Performer",
        "GROUPING": "Grouping",
        "WORK": "Work",
        "MOVEMENTNAME": "Movement Name",
        "MOVEMENTNUMBER": "Movement Number",
        "MOVEMENTCOUNT": "Movement Count",
        "SHOWWORKMOVEMENT": "Show Work and Movement",
        "BPM": "BPM",
        "INITIALKEY": "Initial Key",
        "MOOD": "Mood",
        "COMPILATION": "Compilation",
        "COMMENT": "Comment",
        "LYRICS": "Lyrics",
        "TITLESORT": "Title Sort",
        "ARTISTSORT": "Artist Sort",
        "ALBUMSORT": "Album Sort",
        "ALBUMARTISTSORT": "Album Artist Sort",
        "COMPOSERSORT": "Composer Sort",
        "SHOWSORT": "Show Sort",
        "COPYRIGHT": "Copyright",
        "LABEL": "Label",
        "PRODUCEDNOTICE": "Produced Notice",
        "LICENSE": "License",
        "OWNER": "Owner",
        "ENCODEDBY": "Encoded By",
        "ENCODING": "Encoder Settings",
        "ENCODER": "Encoder",
        "ENCODINGTIME": "Encoding Time",
        "TAGGINGDATE": "Tagging Date",
        "LANGUAGE": "Language",
        "SCRIPT": "Script",
        "MEDIA": "Media",
        "LENGTH": "Length",
        "FILETYPE": "File Type",
        "PLAYLISTDELAY": "Playlist Delay",
        "ORIGINALALBUM": "Original Album",
        "ORIGINALARTIST": "Original Artist",
        "ORIGINALLYRICIST": "Original Lyricist",
        "ORIGINALFILENAME": "Original Filename",
        "RADIOSTATION": "Radio Station",
        "RADIOSTATIONOWNER": "Radio Station Owner",
        "ISRC": "ISRC",
        "ASIN": "ASIN",
        "BARCODE": "Barcode",
        "CATALOGNUMBER": "Catalog Number",
        "RELEASECOUNTRY": "Release Country",
        "RELEASESTATUS": "Release Status",
        "RELEASETYPE": "Release Type",
        "MUSICBRAINZ_ARTISTID": "MusicBrainz Artist ID",
        "MUSICBRAINZ_ALBUMID": "MusicBrainz Release ID",
        "MUSICBRAINZ_ALBUMARTISTID": "MusicBrainz Release Artist ID",
        "MUSICBRAINZ_TRACKID": "MusicBrainz Recording ID",
        "MUSICBRAINZ_RELEASEGROUPID": "MusicBrainz Release Group ID",
        "MUSICBRAINZ_RELEASETRACKID": "MusicBrainz Track ID",
        "MUSICBRAINZ_WORKID": "MusicBrainz Work ID",
        "ACOUSTID_ID": "AcoustID",
        "ACOUSTID_FINGERPRINT": "AcoustID Fingerprint",
        "MUSICIP_PUID": "MusicIP PUID",
        "REPLAYGAIN_TRACK_GAIN": "ReplayGain Track Gain",
        "REPLAYGAIN_TRACK_PEAK": "ReplayGain Track Peak",
        "REPLAYGAIN_ALBUM_GAIN": "ReplayGain Album Gain",
        "REPLAYGAIN_ALBUM_PEAK": "ReplayGain Album Peak",
        "PODCAST": "Podcast",
        "PODCASTCATEGORY": "Podcast Category",
        "PODCASTDESC": "Podcast Description",
        "PODCASTID": "Podcast ID",
        "PODCASTURL": "Podcast URL",
        "TVEPISODE": "TV Episode",
        "TVEPISODEID": "TV Episode ID",
        "TVNETWORK": "TV Network",
        "TVSEASON": "TV Season",
        "TVSHOW": "TV Show",
        "GAPLESSPLAYBACK": "Gapless Playback",
        "URL": "URL",
        "FILEWEBPAGE": "File Webpage",
        "ARTISTWEBPAGE": "Artist Webpage",
        "AUDIOSOURCEWEBPAGE": "Audio Source Webpage",
        "RADIOSTATIONWEBPAGE": "Radio Station Webpage",
        "PAYMENTWEBPAGE": "Payment Webpage",
        "PUBLISHERWEBPAGE": "Publisher Webpage"
    ]
}
