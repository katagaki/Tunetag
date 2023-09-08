//
//  BatchFileInfoView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import ID3TagEditor
import PhotosUI
import SwiftUI

// swiftlint:disable type_body_length
struct BatchFileInfoView: View {
    
    @EnvironmentObject var batchFileManager: BatchFileManager
    @State var tags: [FSFile:ID3Tag] = [:]
    let id3TagEditor = ID3TagEditor()
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
                    .scaledToFill()
                    .frame(width: 100.0, height: 100.0)
                    .clipShape(RoundedRectangle(cornerRadius: 10.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.0)
                            .stroke(.primary, lineWidth: 1/3)
                            .opacity(0.3)
                    )
                    .overlay {
                        PhotosPicker(selection: $selectedAlbumArt,
                                     matching: .images,
                                     photoLibrary: .shared()) {
                            Image(systemName: "pencil")
                        }
                                     .clipShape(Circle())
                                     .buttonStyle(.borderedProminent)
                    }
                    Text("BatchEdit.MultipleFiles")
                        .bold()
                        .textCase(.none)
                        .foregroundStyle(.primary)
                }
                .listRowBackground(Color.clear)
            }
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            Section {
                ListDetailRow(title: "Tag.Title", placeholder: "BatchEdit.Keep", value: $title)
                ListDetailRow(title: "Tag.Artist", placeholder: "BatchEdit.Keep", value: $artist)
                ListDetailRow(title: "Tag.Album", placeholder: "BatchEdit.Keep", value: $album)
                ListDetailRow(title: "Tag.AlbumArtist", placeholder: "BatchEdit.Keep", value: $albumArtist)
                ListDetailRow(title: "Tag.Year", placeholder: "BatchEdit.Keep", value: $year)
                    .keyboardType(.numberPad)
                ListDetailRow(title: "Tag.TrackNumber", placeholder: "BatchEdit.Keep", value: $track)
                    .keyboardType(.numberPad)
                ListDetailRow(title: "Tag.Genre", placeholder: "BatchEdit.Keep", value: $genre)
                ListDetailRow(title: "Tag.Composer", placeholder: "BatchEdit.Keep", value: $composer)
                ListDetailRow(title: "Tag.DiscNumber", placeholder: "BatchEdit.Keep", value: $discNumber)
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
                            saveAllTagData()
                            readAllTagData()
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
            readAllTagData()
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

    // swiftlint:disable cyclomatic_complexity
    // TODO: Optimize this function
    func readAllTagData() {
        debugPrint("Attempting to read tag data for \(batchFileManager.files.count) files...")

        // Check for common tag data betwen all files
        var albumArt: Data?
        var title: String?
        var artist: String?
        var album: String?
        var albumArtist: String?
        var year: Int?
        var track: Int?
        var genre: String?
        var composer: String?
        var discNumber: Int?
        for index in 0..<batchFileManager.files.count {
            debugPrint("Attempting to read tag data for file \(index)...")
            do {
                let tag = try id3TagEditor.read(from: batchFileManager.files[index].path)
                if let tag = tag {
                    tags.updateValue(tag, forKey: batchFileManager.files[index])
                    let tagContentReader = ID3TagContentReader(id3Tag: tag)
                    if index == 0 {
                        title = tagContentReader.title() ?? ""
                        artist = tagContentReader.artist() ?? ""
                        album = tagContentReader.album() ?? ""
                        albumArtist = tagContentReader.albumArtist() ?? ""
                        if let yearFromTag = tagContentReader.recordingDateTime()?.year {
                            year = yearFromTag
                        }
                        if let trackFromTag = tagContentReader.trackPosition()?.position {
                            track = trackFromTag
                        }
                        genre = tagContentReader.genre()?.description ?? ""
                        composer = tagContentReader.composer() ?? ""
                        if let discNumberFromTag = tagContentReader.discPosition()?.position {
                            discNumber = discNumberFromTag
                        }
                        if let albumArtFromTag = tagContentReader.attachedPictures().first(where: { picture in
                            picture.type == .frontCover
                        }) {
                            albumArt = albumArtFromTag.picture
                        }
                    } else {
                        if title != tagContentReader.title() ?? "" { title = nil }
                        if artist != tagContentReader.artist() ?? "" { artist = nil }
                        if album != tagContentReader.album() ?? "" { album = nil }
                        if albumArtist != tagContentReader.albumArtist() ?? "" { albumArtist = nil }
                        if let yearFromTag = tagContentReader.recordingDateTime()?.year {
                            if year != yearFromTag { year = nil }
                        } else {
                            if year != nil { year = nil }
                        }
                        if let trackFromTag = tagContentReader.trackPosition()?.position {
                            if track != trackFromTag { track = nil }
                        } else {
                            if track != nil { track = nil }
                        }
                        if genre != tagContentReader.genre()?.description ?? "" { genre = nil }
                        if composer != tagContentReader.composer() ?? "" { composer = nil }
                        if let discNumberFromTag = tagContentReader.discPosition()?.position {
                            if discNumber != discNumberFromTag { discNumber = nil }
                        } else {
                            if discNumber != nil { discNumber = nil }
                        }
                        if let albumArtFromTag = tagContentReader.attachedPictures().first(where: { picture in
                            picture.type == .frontCover
                        }) {
                            if albumArt != albumArtFromTag.picture { albumArt = nil }
                        } else {
                            if albumArt != nil { albumArt = nil }
                        }
                    }
                }
            } catch {
                debugPrint("Error occurred while reading tags: \n\(error.localizedDescription)")
            }
        }

        // Load data into view
        self.albumArt = albumArt
        self.title = title ?? ""
        self.artist = artist ?? ""
        self.album = album ?? ""
        self.albumArtist = albumArtist ?? ""
        if let year = year { self.year = String(year) }
        if let track = track { self.track = String(track) }
        self.genre = genre ?? ""
        self.composer = composer ?? ""
        if let discNumber = discNumber { self.discNumber = String(discNumber) }
    }
    // swiftlint:enable cyclomatic_complexity

    func saveAllTagData() {
        for file in batchFileManager.files {
            saveTagData(to: file)
        }
    }

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    // TODO: Optimize this function
    func saveTagData(to file: FSFile) {
        debugPrint("Attempting to save tag data...")
        changeSaveState(to: .saving)
        if saveAttemptCount < 3 {
            saveAttemptCount += 1
            do {
                let tag = tags[file]
                var tagBuilder = ID32v3TagBuilder()
                if title != "" {
                    tagBuilder = tagBuilder
                        .title(frame: ID3FrameWithStringContent(content: replaceTokens(title, file: file)))
                } else if let tag = tag,
                          let title = ID3TagContentReader(id3Tag: tag).title() {
                    tagBuilder = tagBuilder
                        .title(frame: ID3FrameWithStringContent(content: replaceTokens(title, file: file)))
                }
                if artist != "" {
                    tagBuilder = tagBuilder
                        .artist(frame: ID3FrameWithStringContent(content: replaceTokens(artist, file: file)))
                } else if let tag = tag,
                          let artist = ID3TagContentReader(id3Tag: tag).artist() {
                    tagBuilder = tagBuilder
                        .artist(frame: ID3FrameWithStringContent(content: replaceTokens(artist, file: file)))
                }
                if album != "" {
                    tagBuilder = tagBuilder
                    .album(frame: ID3FrameWithStringContent(content: replaceTokens(album, file: file)))
                } else if let tag = tag,
                          let album = ID3TagContentReader(id3Tag: tag).album() {
                    tagBuilder = tagBuilder
                        .album(frame: ID3FrameWithStringContent(content: replaceTokens(album, file: file)))
                }
                if albumArtist != "" {
                    tagBuilder = tagBuilder
                        .albumArtist(frame: ID3FrameWithStringContent(content: replaceTokens(albumArtist, file: file)))
                } else if let tag = tag,
                          let albumArtist = ID3TagContentReader(id3Tag: tag).albumArtist() {
                    tagBuilder = tagBuilder
                        .albumArtist(frame: ID3FrameWithStringContent(content: replaceTokens(albumArtist, file: file)))
                }
                if let year = Int(year) {
                    tagBuilder = tagBuilder
                        .recordingYear(frame: ID3FrameWithIntegerContent(value: year))
                } else if let tag = tag,
                          let recordingYear = ID3TagContentReader(id3Tag: tag).recordingYear() {
                    tagBuilder = tagBuilder
                        .recordingYear(frame: ID3FrameWithIntegerContent(value: recordingYear))
                }
                if let track = Int(track) {
                    tagBuilder = tagBuilder
                        .trackPosition(frame: ID3FramePartOfTotal(part: track, total: nil))
                } else if let tag = tag,
                          let track = ID3TagContentReader(id3Tag: tag).trackPosition() {
                    tagBuilder = tagBuilder
                        .trackPosition(frame: ID3FramePartOfTotal(part: track.position, total: track.total))
                }
                if genre != "" {
                    tagBuilder = tagBuilder
                        .genre(frame: ID3FrameGenre(genre: nil, description: replaceTokens(genre, file: file)))
                } else if let tag = tag,
                          let genre = ID3TagContentReader(id3Tag: tag).genre() {
                    tagBuilder = tagBuilder
                        .genre(frame: ID3FrameGenre(genre: genre.identifier, description: genre.description))
                }
                if composer != "" {
                    tagBuilder = tagBuilder
                        .composer(frame: ID3FrameWithStringContent(content: replaceTokens(composer, file: file)))
                } else if let tag = tag,
                          let composer = ID3TagContentReader(id3Tag: tag).composer() {
                    tagBuilder = tagBuilder
                        .composer(frame: ID3FrameWithStringContent(content: composer))
                }
                if let discNumber = Int(discNumber) {
                    tagBuilder = tagBuilder
                        .discPosition(frame: ID3FramePartOfTotal(part: discNumber, total: nil))
                } else if let tag = tag,
                          let discNumber = ID3TagContentReader(id3Tag: tag).discPosition() {
                    tagBuilder = tagBuilder
                        .discPosition(frame: ID3FramePartOfTotal(part: discNumber.position, total: discNumber.total))
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
                } else if let tag = tag,
                          let albumArt = ID3TagContentReader(id3Tag: tag).attachedPictures().first(where: { picture in
                              picture.type == .frontCover
                          }) {
                    tagBuilder = tagBuilder
                        .attachedPicture(pictureType: .frontCover,
                                         frame: ID3FrameAttachedPicture(picture: albumArt.picture,
                                                                        type: .frontCover,
                                                                        format: albumArt.format))
                }
                try id3TagEditor.write(tag: tagBuilder.build(), to: file.path)
                changeSaveState(to: .saved)
            } catch {
                debugPrint("Error occurred while saving tag: \n\(error.localizedDescription)")
                initializeTag(for: file)
                saveTagData(to: file)
            }
        } else {
            saveAttemptCount = 0
        }
    }
    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable function_body_length

    func initializeTag(for file: FSFile) {
        debugPrint("Attempting to initialize tag...")
        do {
            let id3TagEditor = ID3TagEditor()
            let id3Tag = ID32v3TagBuilder()
                .title(frame: ID3FrameWithStringContent(content: ""))
                .build()
            try id3TagEditor.write(tag: id3Tag, to: file.path)
        } catch {
            debugPrint("Error occurred while initializing tag: \n\(error.localizedDescription)")
        }
    }

    func replaceTokens(_ original: String, file: FSFile) -> String {
        var processedString = original
        let componentsSplitByDash = original.components(separatedBy: " - ")
        if componentsSplitByDash.count >= 1 {
            processedString = processedString.replacingOccurrences(of: "%frontsplit%",
                                                                   with: componentsSplitByDash[0])
        } else {
            processedString = processedString.replacingOccurrences(of: "%frontsplit%", 
                                                                   with: "")
        }
        if componentsSplitByDash.count >= 2 {
            processedString = processedString.replacingOccurrences(of: "%backsplit%",
                                                                   with: componentsSplitByDash[1])
        } else {
            processedString = processedString.replacingOccurrences(of: "%backsplit%", 
                                                                   with: "")
        }
        processedString =  processedString.replacingOccurrences(of: "%filename%",
                                                                with: file.name.replacingOccurrences(of: ".mp3",
                                                                                                     with: ""),
                                                                options: .caseInsensitive)
        return processedString
    }

    func changeSaveState(to newState: SaveState) {
        withAnimation(.snappy.speed(2)) {
            saveState = newState
        }
    }

}
// swiftlint:enable type_body_length
