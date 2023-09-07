//
//  FileInfoView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import SwiftTaggerID3
import SwiftUI

struct FileInfoView: View {

    @EnvironmentObject var fileManager: FilesystemManager
    @State var currentFile: FSFile
    @State var mp3File: Mp3File?
    @State var tag: Tag?
    @State var albumArt: Data?
    @State var title: String = ""
    @State var artist: String = ""
    @State var album: String = ""
    @State var albumArtist: String = ""
    @State var year: String = ""
    @State var track: String = ""
    @State var genre: String = ""
    @State var composer: String = ""
    @State var discNumber: String = ""

    var body: some View {
        List {
            Section {
                HStack(alignment: .center, spacing: 8.0) {
                    Group {
                        if let albumArt = albumArt,
                           let albumArtImage = UIImage(data: albumArt) {
                            Image(uiImage: albumArtImage)
                                .resizable()
                        } else {
                            Image(.albumGeneric)
                                .resizable()
                        }
                    }
                    .frame(width: 72.0, height: 72.0)
                    .clipShape(RoundedRectangle(cornerRadius: 10.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.0)
                            .stroke(.primary, lineWidth: 1/3)
                            .opacity(0.3)
                    )
                    .scaledToFit()
                    Text(currentFile.name)
                        .bold()
                        .textCase(.none)
                        .foregroundStyle(.primary)
                }
                .listRowBackground(Color.clear)
            }
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            Section {
                ListDetailRow(title: "Tag.Title", value: $title)
                ListDetailRow(title: "Tag.Artist", value: $artist)
                ListDetailRow(title: "Tag.Album", value: $album)
                ListDetailRow(title: "Tag.AlbumArtist", value: $albumArtist)
                ListDetailRow(title: "Tag.Year", value: year)
                ListDetailRow(title: "Tag.Genre", value: $genre)
                ListDetailRow(title: "Tag.Composer", value: $composer)
                ListDetailRow(title: "Tag.DiscNumber", value: $discNumber)
            } header: {
                ListSectionHeader(text: "FileInfo.TagData")
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // TODO: Save tag
                } label: {
                    Text("Shared.Save")
                }
            }
        }
        .onAppear {
            do {
                mp3File = try Mp3File(location: mp3URL())
                if let mp3File = mp3File {
                    tag = try mp3File.tag()
                    if let tag = tag {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy"
                        title = tag.title
                        artist = tag.artist
                        album = tag.album
                        albumArtist = tag.albumArtist
                        year = dateFormatter.string(from: tag.releaseDateTime)
                        track = tag.trackNumber.index.description
                        genre = tag.genre.genre
                        composer = tag.composer
                        discNumber = tag.discNumber.index.description
                        albumArt = tag[attachedPicture: .frontCover]?.pngData()
                    }
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    func mp3URL() -> URL {
        return URL(fileURLWithPath: currentFile.path)
    }

}
