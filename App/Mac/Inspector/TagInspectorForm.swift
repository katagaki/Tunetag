//
//  TagInspectorForm.swift
//  Tunetag
//

import Prelude
import SwiftUI

/// The tag fields, grouped into the same sections as the iOS editor.
struct TagInspectorForm: View {

    @Bindable var model: TagInspectorModel
    @State private var isSortingExpanded = false
    @State private var isAdvancedExpanded = false

    private var isBatch: Bool {
        model.isBatchEditing
    }

    private var headerTitle: String {
        isBatch
            ? String(format: MacText.string("Window.FileCount"), model.loadedFiles.count)
            : model.loadedFiles.first?.name ?? ""
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    InspectorAlbumArt(albumArt: $model.tag.albumArt, isAlbumArtRemoved: $model.isAlbumArtRemoved)
                    Text(headerTitle)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            Section(MacText.shared("TagEditor.Section.Track")) {
                field("Tag.Title", \.title)
                field("Tag.Artist", \.artist)
                field("Tag.Composer", \.composer)
                field("Tag.Conductor", \.conductor)
                field("Tag.Genre", \.genre)
                field("Tag.Grouping", \.grouping)
                field("Tag.BPM", \.bpm)
            }
            Section {
                field("Tag.Album", \.album)
                field("Tag.AlbumArtist", \.albumArtist)
                field("Tag.Year", \.year)
                NumberPairRow(titleKey: "Tag.Track", number: $model.tag.track, total: $model.tag.trackTotal,
                              isBatch: isBatch)
                NumberPairRow(titleKey: "Tag.Disc", number: $model.tag.discNumber, total: $model.tag.discTotal,
                              isBatch: isBatch)
                CompilationRow(isCompilation: $model.tag.isCompilation, isBatch: isBatch)
            } header: {
                Text(MacText.shared("Tag.Album"))
            } footer: {
                if !model.tag.hasValidNumbers {
                    Text(MacText.shared("TagEditor.InvalidNumber.Message"))
                        .foregroundStyle(.red)
                }
            }
            Section(MacText.shared("TagEditor.Section.Publishing")) {
                field("Tag.Publisher", \.publisher)
                field("Tag.Copyright", \.copyright)
                field("Tag.EncodedBy", \.encodedBy)
            }
            Section(MacText.shared("TagEditor.Section.CommentLyrics")) {
                field("Tag.Comment", \.comment, isMultiline: true)
                field("Tag.Lyrics", \.lyrics, isMultiline: true)
            }
            Section {
                DisclosureGroup(MacText.shared("TagEditor.Section.Sorting"), isExpanded: $isSortingExpanded) {
                    field("Tag.SortTitle", \.titleSortOrder)
                    field("Tag.SortArtist", \.artistSortOrder)
                    field("Tag.SortAlbum", \.albumSortOrder)
                    field("Tag.SortAlbumArtist", \.albumArtistSortOrder)
                    field("Tag.SortComposer", \.composerSortOrder)
                }
            } footer: {
                if isSortingExpanded {
                    Text(MacText.shared("TagEditor.Section.Sorting.Footer"))
                }
            }
            if model.canEditExtendedTags {
                // Lists identifiers and ReplayGain too, so the read-only section isn't needed
                ExtendedTagsSection(model: model)
            } else if !isBatch && (model.tag.hasIdentifiers || model.tag.hasReplayGain) {
                AdvancedInformationSection(tag: model.tag, isExpanded: $isAdvancedExpanded)
            }
        }
        .formStyle(.grouped)
        .disabled(model.isLoading || model.isSaving)
        .opacity(model.isLoading ? 0.5 : 1)
        .animation(.default.speed(2), value: model.isLoading)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            InspectorActionBar(model: model)
        }
    }

    private func field(_ titleKey: String, _ keyPath: WritableKeyPath<Tag, String?>,
                       isMultiline: Bool = false) -> TagFieldRow {
        TagFieldRow(titleKey: titleKey, value: $model.tag[dynamicMember: keyPath], isBatch: isBatch,
                    isMultiline: isMultiline)
    }
}

private struct AdvancedInformationSection: View {

    let tag: Tag
    @Binding var isExpanded: Bool

    var body: some View {
        Section {
            DisclosureGroup(MacText.shared("TagEditor.Section.AdvancedInformation"), isExpanded: $isExpanded) {
                if tag.hasIdentifiers {
                    row("Tag.ISRC", tag.isrc)
                    row("Tag.ReleaseID", tag.musicBrainzReleaseID)
                    row("Tag.RecordingID", tag.musicBrainzRecordingID)
                }
                if tag.hasReplayGain {
                    row("Tag.TrackGain", tag.replayGainTrackGain)
                    row("Tag.TrackPeak", tag.replayGainTrackPeak)
                    row("Tag.AlbumGain", tag.replayGainAlbumGain)
                    row("Tag.AlbumPeak", tag.replayGainAlbumPeak)
                }
            }
        } footer: {
            if isExpanded && tag.hasIdentifiers {
                Text(MacText.shared("TagEditor.Section.Identifiers.Footer"))
            }
        }
    }

    private func row(_ titleKey: String, _ value: String?) -> some View {
        LabeledContent(MacText.shared(titleKey)) {
            Text(value ?? "")
                .textSelection(.enabled)
        }
    }
}
