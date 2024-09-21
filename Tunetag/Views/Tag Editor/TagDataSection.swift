//
//  TagDataSection.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import Combine
import Komponents
import SwiftUI

struct TagDataSection: View {

    @Binding var tagData: Tag
    var focusedField: FocusState<FocusedField?>.Binding?

    var placeholder: String?

    var body: some View {
        Section {
            if let focusedField = focusedField {
                ListInputRow(title: "Tag.Title", value: $tagData.title,
                             focusedFieldValue: .title, focusedField: focusedField)
                ListInputRow(title: "Tag.Artist", value: $tagData.artist,
                             focusedFieldValue: .artist, focusedField: focusedField)
                ListInputRow(title: "Tag.Album", value: $tagData.album,
                             focusedFieldValue: .album, focusedField: focusedField)
                ListInputRow(title: "Tag.AlbumArtist", value: $tagData.albumArtist,
                             focusedFieldValue: .albumArtist, focusedField: focusedField)
                ListInputRow(title: "Tag.Year", value: $tagData.year,
                             focusedFieldValue: .year, focusedField: focusedField)
                .keyboardType(.numberPad)
                ListInputRow(title: "Tag.TrackNumber", value: $tagData.track,
                             focusedFieldValue: .trackNumber, focusedField: focusedField)
                .keyboardType(.numberPad)
                ListInputRow(title: "Tag.Genre", value: $tagData.genre,
                             focusedFieldValue: .genre, focusedField: focusedField)
                .keyboardType(.asciiCapable)
                ListInputRow(title: "Tag.Composer", value: $tagData.composer,
                             focusedFieldValue: .composer, focusedField: focusedField)
                ListInputRow(title: "Tag.DiscNumber", value: $tagData.discNumber,
                             focusedFieldValue: .discNumber, focusedField: focusedField)
                .keyboardType(.numberPad)
            } else {
                ListDetailRow(title: "Tag.Title", value: tagData.title)
                ListDetailRow(title: "Tag.Artist", value: tagData.artist)
                ListDetailRow(title: "Tag.Album", value: tagData.album)
                ListDetailRow(title: "Tag.AlbumArtist", value: tagData.albumArtist)
                ListDetailRow(title: "Tag.Year", value: tagData.year)
                ListDetailRow(title: "Tag.TrackNumber", value: tagData.track)
                ListDetailRow(title: "Tag.Genre", value: tagData.genre)
                ListDetailRow(title: "Tag.Composer", value: tagData.composer)
                ListDetailRow(title: "Tag.DiscNumber", value: tagData.discNumber)
            }
        } header: {
            if #available(iOS 17.0, *) {
                ListSectionHeader(text: "TagEditor.TagData")
                    .popoverTip(AvailableTokensTip(), arrowEdge: .bottom)
            } else {
                ListSectionHeader(text: "TagEditor.TagData")
            }
        }
        .onReceive(Just(tagData.year)) { _ in
            if let year = tagData.year {
                tagData.year = year.filter({ $0.isNumber })
                tagData.year = String(year.prefix(4))
            }
        }
        .onReceive(Just(tagData.track)) { _ in
            if let track = tagData.track {
                tagData.track = track.filter({ $0.isNumber })
            }
        }
        .onReceive(Just(tagData.genre)) { _ in
            if let genre = tagData.genre {
                tagData.genre = genre.filter({ $0.isLetter || $0.isWhitespace })
            }
        }
        .onReceive(Just(tagData.discNumber)) { _ in
            if let discNumber = tagData.discNumber {
                tagData.discNumber = discNumber.filter({ $0.isNumber })
            }
        }
    }
}
