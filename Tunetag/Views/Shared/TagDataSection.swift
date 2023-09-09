//
//  TagDataSection.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import SwiftUI

struct TagDataSection: View {

    @Binding var tagData: Tag

    var placeholder: String?

    var body: some View {
        Section {
            ListDetailRow(title: "Tag.Title", placeholder: placeholder, value: $tagData.title)
            ListDetailRow(title: "Tag.Artist", placeholder: placeholder, value: $tagData.artist)
            ListDetailRow(title: "Tag.Album", placeholder: placeholder, value: $tagData.album)
            ListDetailRow(title: "Tag.AlbumArtist", placeholder: placeholder, value: $tagData.albumArtist)
            ListDetailRow(title: "Tag.Year", placeholder: placeholder, value: $tagData.year)
                .keyboardType(.numberPad)
            ListDetailRow(title: "Tag.TrackNumber", placeholder: placeholder, value: $tagData.track)
                .keyboardType(.numberPad)
            ListDetailRow(title: "Tag.Genre", placeholder: placeholder, value: $tagData.genre)
            ListDetailRow(title: "Tag.Composer", placeholder: placeholder, value: $tagData.composer)
            ListDetailRow(title: "Tag.DiscNumber", placeholder: placeholder, value: $tagData.discNumber)
                .keyboardType(.numberPad)
        } header: {
            ListSectionHeader(text: "FileInfo.TagData")
                .font(.body)
        }
    }
}
