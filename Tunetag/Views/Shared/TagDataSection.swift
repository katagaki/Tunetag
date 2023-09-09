//
//  TagDataSection.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import SwiftUI

struct TagDataSection: View {

    @Binding var tagData: Tag
    var focusedField: FocusState<FocusedField?>.Binding?

    var placeholder: String?

    var body: some View {
        Section {
            if let focusedField = focusedField {
                ListInputRow(title: "Tag.Title", placeholder: placeholder,
                              value: $tagData.title, focusedFieldValue: .title, focusedField: focusedField)
                ListInputRow(title: "Tag.Artist", placeholder: placeholder,
                              value: $tagData.artist, focusedFieldValue: .artist, focusedField: focusedField)
                ListInputRow(title: "Tag.Album", placeholder: placeholder,
                              value: $tagData.album, focusedFieldValue: .album, focusedField: focusedField)
                ListInputRow(title: "Tag.AlbumArtist", placeholder: placeholder,
                              value: $tagData.albumArtist, focusedFieldValue: .albumArtist, focusedField: focusedField)
                ListInputRow(title: "Tag.Year", placeholder: placeholder,
                              value: $tagData.year, focusedFieldValue: .year, focusedField: focusedField)
                .keyboardType(.numberPad)
                ListInputRow(title: "Tag.TrackNumber", placeholder: placeholder,
                              value: $tagData.track, focusedFieldValue: .trackNumber, focusedField: focusedField)
                .keyboardType(.numberPad)
                ListInputRow(title: "Tag.Genre", placeholder: placeholder,
                              value: $tagData.genre, focusedFieldValue: .genre, focusedField: focusedField)
                .keyboardType(.asciiCapable)
                ListInputRow(title: "Tag.Composer", placeholder: placeholder,
                              value: $tagData.composer, focusedFieldValue: .composer, focusedField: focusedField)
                ListInputRow(title: "Tag.DiscNumber", placeholder: placeholder,
                              value: $tagData.discNumber, focusedFieldValue: .discNumber, focusedField: focusedField)
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
            ListSectionHeader(text: "TagEditor.TagData")
                .font(.body)
        }
        .onChange(of: tagData.year) { oldValue, newValue in
            if containsAnythingOtherThanNumbers(newValue) || newValue.count > 4 {
                tagData.year = oldValue
            }
        }
        .onChange(of: tagData.track) { oldValue, newValue in
            if containsAnythingOtherThanNumbers(newValue) {
                tagData.track = oldValue
            }
        }
        .onChange(of: tagData.genre) { oldValue, newValue in
            if containsAnythingOtherThanAlphanumerics(newValue) {
                tagData.genre = oldValue
            }
        }
        .onChange(of: tagData.discNumber) { oldValue, newValue in
            if containsAnythingOtherThanNumbers(newValue) {
                tagData.discNumber = oldValue
            }
        }
    }

    func containsAnythingOtherThanAlphanumerics(_ string: String) -> Bool {
        let validCharacters: CharacterSet = .alphanumerics.union(.whitespaces).inverted
        let characterRange = string.rangeOfCharacter(from: validCharacters)
        return characterRange != nil
    }

    func containsAnythingOtherThanNumbers(_ string: String) -> Bool {
        let validCharacters: CharacterSet = .init(charactersIn: "0123456789").inverted
        let characterRange = string.rangeOfCharacter(from: validCharacters)
        return characterRange != nil
    }
}
