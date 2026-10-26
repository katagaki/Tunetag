//
//  TagEditorWideLayout.swift
//  Tunetag
//

import Prelude
import SwiftUI

/// A desktop-style layout for wide windows, such as on iPad. Each section is a card, and its fields flow into as
/// many columns as the window has room for.
struct TagEditorWideLayout<Header: View, SidebarFooter: View>: View {

    @Binding var tagData: Tag
    var focusedField: FocusState<FocusedField?>.Binding
    var isBatchEditing: Bool
    var showsAdvancedInformation: Bool
    @Binding var isSortingExpanded: Bool
    /// Set while the sidebar is shown, so the editor can move its Save button into it.
    @Binding var isSidebarShown: Bool
    @ViewBuilder var header: () -> Header
    @ViewBuilder var sidebarFooter: () -> SidebarFooter

    @State var size: CGSize = .zero
    @State var isAdvancedExpanded: Bool = false

    /// Shows the file header in a sidebar next to the fields when the window is wide, or landscape-shaped and
    /// wide enough that a header on top would push the fields down.
    var showsSidebar: Bool {
        size.width >= 900.0 || (size.width >= 700.0 && size.width > size.height * 1.2)
    }

    var body: some View {
        Group {
            if showsSidebar {
                HStack(alignment: .top, spacing: 0.0) {
                    ScrollView {
                        VStack(spacing: 24.0) {
                            header()
                            sidebarFooter()
                        }
                        .padding(24.0)
                    }
                    .frame(width: 300.0)
                    Divider()
                    ScrollView {
                        cards
                            .padding(24.0)
                    }
                }
            } else {
                ScrollView {
                    VStack(spacing: 24.0) {
                        header()
                        cards
                    }
                    .padding(24.0)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .environment(\.isTagFieldBoxed, true)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            size = newSize
        }
        .onChange(of: showsSidebar, initial: true) { _, newValue in
            isSidebarShown = newValue
        }
    }

    var cards: some View {
        VStack(alignment: .leading, spacing: 24.0) {
            TagFieldCard(title: "TagEditor.Section.Track") {
                inputRow("Tag.Title", $tagData.title, .title)
                inputRow("Tag.Artist", $tagData.artist, .artist)
                inputRow("Tag.Composer", $tagData.composer, .composer)
                inputRow("Tag.Conductor", $tagData.conductor, .conductor)
                inputRow("Tag.Genre", $tagData.genre, .genre)
                inputRow("Tag.Grouping", $tagData.grouping, .grouping)
                inputRow("Tag.BPM", $tagData.bpm, .bpm)
                    .keyboardType(.numberPad)
            }
            TagFieldCard(title: "Tag.Album") {
                inputRow("Tag.Album", $tagData.album, .album)
                inputRow("Tag.AlbumArtist", $tagData.albumArtist, .albumArtist)
                inputRow("Tag.Year", $tagData.year, .year)
                    .keyboardType(.numberPad)
                ListNumberPairRow(title: "Tag.Track", number: $tagData.track, total: $tagData.trackTotal,
                                  numberField: .trackNumber, totalField: .trackTotal,
                                  focusedField: focusedField, isBatchEditing: isBatchEditing)
                ListNumberPairRow(title: "Tag.Disc", number: $tagData.discNumber, total: $tagData.discTotal,
                                  numberField: .discNumber, totalField: .discTotal,
                                  focusedField: focusedField, isBatchEditing: isBatchEditing)
                ListCompilationRow(isCompilation: $tagData.isCompilation, isBatchEditing: isBatchEditing)
                    .padding(.top, isBatchEditing ? 0.0 : 14.0)
            }
            TagFieldCard(title: "TagEditor.Section.Publishing") {
                inputRow("Tag.Publisher", $tagData.publisher, .publisher)
                inputRow("Tag.Copyright", $tagData.copyright, .copyright)
                inputRow("Tag.EncodedBy", $tagData.encodedBy, .encodedBy)
            }
            TagFieldCard(title: "TagEditor.Section.CommentLyrics", minimumColumnWidth: 320.0) {
                inputRow("Tag.Comment", $tagData.comment, .comment, isMultiline: true)
                inputRow("Tag.Lyrics", $tagData.lyrics, .lyrics, isMultiline: true)
            }
            TagFieldCard(title: "TagEditor.Section.Sorting", footer: "TagEditor.Section.Sorting.Footer",
                         isExpanded: $isSortingExpanded) {
                inputRow("Tag.SortTitle", $tagData.titleSortOrder, .titleSortOrder)
                inputRow("Tag.SortArtist", $tagData.artistSortOrder, .artistSortOrder)
                inputRow("Tag.SortAlbum", $tagData.albumSortOrder, .albumSortOrder)
                inputRow("Tag.SortAlbumArtist", $tagData.albumArtistSortOrder, .albumArtistSortOrder)
                inputRow("Tag.SortComposer", $tagData.composerSortOrder, .composerSortOrder)
            }
            if showsAdvancedInformation && (tagData.hasIdentifiers || tagData.hasReplayGain) {
                TagFieldCard(title: "TagEditor.Section.AdvancedInformation",
                             footer: tagData.hasIdentifiers ? "TagEditor.Section.Identifiers.Footer" : nil,
                             isExpanded: $isAdvancedExpanded) {
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
            }
        }
        .frame(maxWidth: 1200.0)
        .frame(maxWidth: .infinity)
    }

    func inputRow(_ title: String, _ value: Binding<String?>, _ field: FocusedField,
                  isMultiline: Bool = false) -> ListInputRow {
        ListInputRow(title: title, value: value, field: field, focusedField: focusedField,
                     isBatchEditing: isBatchEditing, isMultiline: isMultiline)
    }
}

/// A titled card whose fields are laid out in an adaptive grid.
struct TagFieldCard<Content: View>: View {

    var title: String
    var footer: String?
    var isExpanded: Binding<Bool>?
    var minimumColumnWidth: CGFloat
    @ViewBuilder var content: () -> Content

    init(title: String, footer: String? = nil, isExpanded: Binding<Bool>? = nil,
         minimumColumnWidth: CGFloat = 220.0, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.footer = footer
        self.isExpanded = isExpanded
        self.minimumColumnWidth = minimumColumnWidth
        self.content = content
    }

    var showsContent: Bool {
        isExpanded?.wrappedValue ?? true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Group {
                if let isExpanded {
                    CollapsibleSectionHeader(text: title, isExpanded: isExpanded)
                } else {
                    ListSectionHeader(text: title)
                }
            }
            .padding(.horizontal, 4.0)
            if showsContent {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumColumnWidth), spacing: 16.0,
                                             alignment: .top)],
                          alignment: .leading, spacing: 16.0) {
                    Group {
                        content()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16.0)
                .background(Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 16.0))
                if let footer {
                    Text(LocalizedStringKey(footer))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4.0)
                }
            }
        }
    }
}
