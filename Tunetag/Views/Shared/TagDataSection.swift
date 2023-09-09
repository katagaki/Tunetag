//
//  TagDataSection.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import SwiftUI

struct TagDataSection: View {

    @Binding var tagData: Tag
    var focusedField: FocusState<FocusedField?>.Binding

    var placeholder: String?

    var body: some View {
        Section {
            ListDetailRow(title: "Tag.Title", placeholder: placeholder,
                          value: $tagData.title, focusedFieldValue: .title, focusedField: focusedField)
            ListDetailRow(title: "Tag.Artist", placeholder: placeholder,
                          value: $tagData.artist, focusedFieldValue: .artist, focusedField: focusedField)
            ListDetailRow(title: "Tag.Album", placeholder: placeholder,
                          value: $tagData.album, focusedFieldValue: .album, focusedField: focusedField)
            ListDetailRow(title: "Tag.AlbumArtist", placeholder: placeholder,
                          value: $tagData.albumArtist, focusedFieldValue: .albumArtist, focusedField: focusedField)
            ListDetailRow(title: "Tag.Year", placeholder: placeholder,
                          value: $tagData.year, focusedFieldValue: .year, focusedField: focusedField)
                .keyboardType(.numberPad)
            ListDetailRow(title: "Tag.TrackNumber", placeholder: placeholder,
                          value: $tagData.track, focusedFieldValue: .trackNumber, focusedField: focusedField)
                .keyboardType(.numberPad)
            ListDetailRow(title: "Tag.Genre", placeholder: placeholder,
                          value: $tagData.genre, focusedFieldValue: .genre, focusedField: focusedField)
            ListDetailRow(title: "Tag.Composer", placeholder: placeholder,
                          value: $tagData.composer, focusedFieldValue: .composer, focusedField: focusedField)
            ListDetailRow(title: "Tag.DiscNumber", placeholder: placeholder,
                          value: $tagData.discNumber, focusedFieldValue: .discNumber, focusedField: focusedField)
                .keyboardType(.numberPad)
        } header: {
            ListSectionHeader(text: "TagEditor.TagData")
                .font(.body)
        }
    }
}
