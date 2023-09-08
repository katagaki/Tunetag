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
    let id3TagEditor = ID3TagEditor()
    @State var mp3File: Mp3File?
    @State var tag: ID3Tag?
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
    @State var selectedAlbumArt: PhotosPickerItem?
    @State var saveState: SaveState = .notSaved

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
                    .frame(width: 100.0, height: 100.0)
                    .clipShape(RoundedRectangle(cornerRadius: 10.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.0)
                            .stroke(.primary, lineWidth: 1/3)
                            .opacity(0.3)
                    )
                    .scaledToFit()
                    .overlay {
                        PhotosPicker(selection: $selectedAlbumArt,
                                     matching: .images,
                                     photoLibrary: .shared()) {
                            Image(systemName: "pencil")
                        }
                                     .clipShape(Circle())
                                     .buttonStyle(.borderedProminent)
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
                HStack {
                    switch saveState {
                    case .notSaved:
                        Button {
                            saveTagData()
                            readTagData()
                        } label: {
                            Text("Shared.Save")
                        }
                    case .saving:
                        ProgressView()
                            .progressViewStyle(.circular)
                    case .saved:
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.multicolor)
                    }
                }
                .transition(AnyTransition.asymmetric(insertion: .scale, removal: .identity).animation(.snappy))
            }
        }
        .onAppear {
            readTagData()
        }
        .onChange(of: selectedAlbumArt, initial: false) {
            Task {
                if let selectedAlbumArt = selectedAlbumArt,
                    let data = try? await selectedAlbumArt.loadTransferable(type: Data.self) {
                    albumArt = data
                }
            }
        }
        .onChange(of: saveState) {
            switch saveState {
            case .saved:
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    changeSaveState(to: .notSaved)
                }
            default:
                break
            }
        }
    }

    func readTagData() {
        debugPrint("Attempting to read tag data...")
        do {
            tag = try id3TagEditor.read(from: currentFile.path)
            if let tag = tag {
                let tagContentReader = ID3TagContentReader(id3Tag: tag)
                title = tagContentReader.title() ?? ""
                artist = tagContentReader.artist() ?? ""
                album = tagContentReader.album() ?? ""
                albumArtist = tagContentReader.albumArtist() ?? ""
                if let year = tagContentReader.recordingDateTime()?.year {
                    self.year = String(year)
                }
                if let track = tagContentReader.trackPosition()?.position {
                    self.track = String(track)
                }
                genre = tagContentReader.genre()?.description ?? ""
                composer = tagContentReader.composer() ?? ""
                if let discNumber = tagContentReader.discPosition()?.position {
                    self.discNumber = String(discNumber)
                }
                if let albumArt = tagContentReader.attachedPictures().first(where: { picture in
                    picture.type == .frontCover
                }) {
                    self.albumArt = albumArt.picture
                }
            }
        } catch {
            debugPrint("Error occurred while reading tags: \n\(error.localizedDescription)")
        }
    }

    func saveTagData() {
        debugPrint("Attempting to save tag data...")
        changeSaveState(to: .saving)
        if saveAttemptCount < 3 {
            saveAttemptCount += 1
            do {
            var tagBuilder = ID32v3TagBuilder()
                .title(frame: ID3FrameWithStringContent(content: title))
                .artist(frame: ID3FrameWithStringContent(content: artist))
                .album(frame: ID3FrameWithStringContent(content: album))
                .albumArtist(frame: ID3FrameWithStringContent(content: albumArtist))
                if let year = Int(year) {
                    tagBuilder = tagBuilder
                        .recordingYear(frame: ID3FrameWithIntegerContent(value: year))
                }
                if let track = Int(track) {
                    tagBuilder = tagBuilder
                        .trackPosition(frame: ID3FramePartOfTotal(part: track, total: nil))
                }
                tagBuilder = tagBuilder
                    .genre(frame: ID3FrameGenre(genre: nil, description: genre))
                    .composer(frame: ID3FrameWithStringContent(content: composer))
                if let discNumber = Int(discNumber) {
                    tagBuilder = tagBuilder
                        .discPosition(frame: ID3FramePartOfTotal(part: discNumber, total: nil))
                }
                if let albumArt = albumArt,
                   let albumArtUIImage = UIImage(data: albumArt) {
                    if let pngData = albumArtUIImage.pngData() {
                        debugPrint("PNG album art detected!")
                        tagBuilder = tagBuilder
                            .attachedPicture(pictureType: .frontCover,
                                             frame: ID3FrameAttachedPicture(picture: pngData,
                                                                            type: .frontCover,
                                                                            format: .png))
                    } else if let jpgData = albumArtUIImage.jpegData(compressionQuality: 1.0) {
                        debugPrint("JPG album art detected!")
                        tagBuilder = tagBuilder
                            .attachedPicture(pictureType: .frontCover,
                                             frame: ID3FrameAttachedPicture(picture: jpgData,
                                                                            type: .frontCover,
                                                                            format: .jpeg))
                    } else {
                        debugPrint("Unsupported album art detected!")
                    }
                }
                try id3TagEditor.write(tag: tagBuilder.build(), to: currentFile.path)
                changeSaveState(to: .saved)
            } catch {
                debugPrint("Error occurred while saving tag: \n\(error.localizedDescription)")
                initializeTag()
                saveTagData()
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

    func changeSaveState(to newState: SaveState) {
        withAnimation(.snappy.speed(2)) {
            saveState = newState
        }
    }

}
