//
//  TagDataSection.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import Prelude
import SwiftUI

struct TagDataSection: View {

    @Binding var tagData: Tag
    var focusedField: FocusState<FocusedField?>.Binding
    var isBatchEditing: Bool = false

    @Binding var isSortingExpanded: Bool

    var body: some View {
        Section {
            inputRow("Tag.Title", $tagData.title, .title)
            inputRow("Tag.Artist", $tagData.artist, .artist)
            inputRow("Tag.Composer", $tagData.composer, .composer)
            inputRow("Tag.Conductor", $tagData.conductor, .conductor)
            inputRow("Tag.Genre", $tagData.genre, .genre)
            inputRow("Tag.Grouping", $tagData.grouping, .grouping)
            inputRow("Tag.BPM", $tagData.bpm, .bpm)
                .keyboardType(.numberPad)
        } header: {
            ListSectionHeader(text: "TagEditor.Section.Track")
        }

        Section {
            inputRow("Tag.Album", $tagData.album, .album)
            inputRow("Tag.AlbumArtist", $tagData.albumArtist, .albumArtist)
            inputRow("Tag.Year", $tagData.year, .year)
                .keyboardType(.numberPad)
            ListTrackDiscRow(tagData: $tagData, focusedField: focusedField, isBatchEditing: isBatchEditing)
            ListCompilationRow(isCompilation: $tagData.isCompilation, isBatchEditing: isBatchEditing)
        } header: {
            ListSectionHeader(text: "Tag.Album")
        }

        Section {
            inputRow("Tag.Publisher", $tagData.publisher, .publisher)
            inputRow("Tag.Copyright", $tagData.copyright, .copyright)
            inputRow("Tag.EncodedBy", $tagData.encodedBy, .encodedBy)
        } header: {
            ListSectionHeader(text: "TagEditor.Section.Publishing")
        }

        Section {
            inputRow("Tag.Comment", $tagData.comment, .comment, isMultiline: true)
            inputRow("Tag.Lyrics", $tagData.lyrics, .lyrics, isMultiline: true)
        } header: {
            ListSectionHeader(text: "TagEditor.Section.CommentLyrics")
        }

        Section {
            if isSortingExpanded {
                inputRow("Tag.SortTitle", $tagData.titleSortOrder, .titleSortOrder)
                inputRow("Tag.SortArtist", $tagData.artistSortOrder, .artistSortOrder)
                inputRow("Tag.SortAlbum", $tagData.albumSortOrder, .albumSortOrder)
                inputRow("Tag.SortAlbumArtist", $tagData.albumArtistSortOrder, .albumArtistSortOrder)
                inputRow("Tag.SortComposer", $tagData.composerSortOrder, .composerSortOrder)
            }
        } header: {
            CollapsibleSectionHeader(text: "TagEditor.Section.Sorting", isExpanded: $isSortingExpanded)
        } footer: {
            if isSortingExpanded {
                Text("TagEditor.Section.Sorting.Footer")
            }
        }
    }

    func inputRow(_ title: String, _ value: Binding<String?>, _ field: FocusedField,
                  isMultiline: Bool = false) -> ListInputRow {
        ListInputRow(title: title, value: value, field: field, focusedField: focusedField,
                     isBatchEditing: isBatchEditing, isMultiline: isMultiline)
    }
}

struct TagInfoSection: View {

    var tagData: Tag

    @State var isExpanded: Bool = false

    var body: some View {
        if tagData.hasIdentifiers || tagData.hasReplayGain {
            Section {
                if isExpanded {
                    if tagData.hasIdentifiers {
                        ListDetailRow(title: "Tag.ISRC", value: tagData.isrc)
                        ListDetailRow(title: "Tag.ReleaseID", value: tagData.musicBrainzReleaseID)
                        ListDetailRow(title: "Tag.RecordingID", value: tagData.musicBrainzRecordingID)
                    }
                    if tagData.hasReplayGain {
                        ListDetailRow(title: "Tag.TrackGain", value: tagData.replayGainTrackGain)
                        ListDetailRow(title: "Tag.TrackPeak", value: tagData.replayGainTrackPeak)
                        ListDetailRow(title: "Tag.AlbumGain", value: tagData.replayGainAlbumGain)
                        ListDetailRow(title: "Tag.AlbumPeak", value: tagData.replayGainAlbumPeak)
                    }
                }
            } header: {
                CollapsibleSectionHeader(text: "TagEditor.Section.AdvancedInformation", isExpanded: $isExpanded)
            } footer: {
                if isExpanded && tagData.hasIdentifiers {
                    Text("TagEditor.Section.Identifiers.Footer")
                }
            }
        }
    }
}
