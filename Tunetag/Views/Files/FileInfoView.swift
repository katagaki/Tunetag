//
//  FileInfoView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import ID3TagEditor
import PhotosUI
import SwiftConvenienceExtensions
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
    @State var saveAttemptCount: Int = 0
    @State var isAlbumArtDownloading: Bool = false
    @State var selectedAlbumArt: PhotosPickerItem? {
        didSet {
            if let selectedAlbumArt {
                loadAlbumArt(from: selectedAlbumArt)
                isAlbumArtDownloading = true
            } else {
                isAlbumArtDownloading = false
            }
        }
    }

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
                    .overlay {
                        if !isAlbumArtDownloading {
                            PhotosPicker(selection: $selectedAlbumArt,
                                         matching: .images,
                                         photoLibrary: .shared()) {
                                Color.clear
                            }
                        }
                    }
                    .overlay {
                        if isAlbumArtDownloading {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
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
                ListDetailRow(title: "Tag.Year", value: $year)
                    .keyboardType(.numberPad)
                ListDetailRow(title: "Tag.TrackNumber", value: $track)
                    .keyboardType(.numberPad)
                ListDetailRow(title: "Tag.Genre", value: $genre)
                ListDetailRow(title: "Tag.Composer", value: $composer)
                ListDetailRow(title: "Tag.DiscNumber", value: $discNumber)
                    .keyboardType(.numberPad)
            } header: {
                ListSectionHeader(text: "FileInfo.TagData")
                    .font(.body)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    saveTagData()
                    refreshTagData()
                } label: {
                    Text("Shared.Save")
                }
            }
        }
        .onAppear {
            refreshTagData()
        }
    }

    func refreshTagData() {
        debugPrint("Attempting to read tag data...")
        do {
            mp3File = try Mp3File(location: mp3URL())
            if let mp3File = mp3File {
                do {
                    tag = try mp3File.tag()
                    if let tag = tag {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy"
                        title = tag.title ?? ""
                        artist = tag.artist ?? ""
                        album = tag.album ?? ""
                        albumArtist = tag.albumArtist ?? ""
                        if let releaseDateTime = tag.releaseDateTime {
                            year = dateFormatter.string(from: releaseDateTime)
                        } else {
                            year = ""
                        }
                        track = tag.trackNumber.index.description
                        genre = tag.genre.genre ?? ""
                        composer = tag.composer ?? ""
                        discNumber = tag.discNumber.index.description
                        albumArt = tag[attachedPicture: .frontCover]?.pngData()
                    }
                } catch {
                    debugPrint("Error occurred while reading tag: \n\(error.localizedDescription)")
                }
            }
        } catch {
            debugPrint("Error occurred while reading file: \n\(error.localizedDescription)")
        }
    }

    func saveTagData() {
        debugPrint("Attempting to save tag data...")
        if saveAttemptCount < 3 {
            saveAttemptCount += 1
            var newTag = tag ?? Tag(version: .v2_3)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy"
            newTag.title = title
            newTag.artist = artist
            newTag.album = album
            newTag.albumArtist = albumArtist
            newTag.releaseDateTime = dateFormatter.date(from: year)
            if let track = Int(track) {
                newTag.trackNumber = IntIndex(index: track, total: nil)
            } else {
                newTag["trackNumber"] = nil
            }
            newTag.genre = (genreCategory: nil, genre: genre)
            newTag.composer = composer
            if let discNumber = Int(discNumber) {
                newTag.discNumber = IntIndex(index: discNumber, total: nil)
            } else {
                newTag["discNumber"] = nil
            }
//            newTag.set(attachedPicture: .frontCover,
//                       imageLocation: albumArtURL,
//                       description: nil)
            do {
                if let mp3File = mp3File {
                    try mp3File.write(tag: &newTag, version: .v2_3, outputLocation: mp3URL())
                }
            } catch {
                debugPrint("Error occurred while saving tag: \n\(error.localizedDescription)")
                initializeTag()
                do {
                    mp3File = try Mp3File(location: mp3URL())
                    saveTagData()
                } catch {
                    debugPrint("Error occurred while re-reading tag after initialization:\n" +
                               "\(error.localizedDescription)")
                }
            }
        } else {
            saveAttemptCount = 0
        }
    }

    func initializeTag() {
        debugPrint("Attempting to initialize tag...")
        do {
            let id3TagEditor = ID3TagEditor()
            let id3Tag = ID32v3TagBuilder()
                .title(frame: ID3FrameWithStringContent(content: ""))
                .build()
            try id3TagEditor.write(tag: id3Tag, to: currentFile.path)
        } catch {
            debugPrint("Error occurred while initializing tag: \n\(error.localizedDescription)")
        }
    }

    func mp3URL() -> URL {
        return URL(fileURLWithPath: currentFile.path)
    }

    func loadAlbumArt(from imageSelection: PhotosPickerItem) {
        debugPrint("Reading image data...")
        imageSelection.loadTransferable(type: AlbumArt.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let albumArt):
                    if let albumArt = albumArt,
                       let image = albumArt.image {
                        self.albumArt = image.pngData()
                    }
                default:
                    break
                }
            }
        }
    }

}
