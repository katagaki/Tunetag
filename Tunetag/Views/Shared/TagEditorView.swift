//
//  TagEditorView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import ID3TagEditor
import PhotosUI
import SwiftUI
import TipKit

// swiftlint:disable type_body_length
struct TagEditorView: View {

    @State var files: [FSFile]
    @State var tags: [FSFile: ID3Tag] = [:]
    let id3TagEditor = ID3TagEditor()
    @State var tagData = Tag()
    @State var selectedAlbumArt: PhotosPickerItem?
    @State var saveState: SaveState = .notSaved

    var availableTokensTip = AvailableTokensTip()

    var body: some View {
        List {
            if files.count == 1 {
                FileHeaderSection(filename: files[0].name,
                                  albumArt: $tagData.albumArt,
                                  selectedAlbumArt: $selectedAlbumArt)
                TagDataSection(tagData: $tagData)
            } else {
                FileHeaderSection(filename: NSLocalizedString("BatchEdit.MultipleFiles", comment: ""),
                                  albumArt: $tagData.albumArt,
                                  selectedAlbumArt: $selectedAlbumArt)
                TagDataSection(tagData: $tagData,
                               placeholder: NSLocalizedString("BatchEdit.Keep", comment: ""))
            }
            Section {
                AvailableTokenRow(tokenName: "FILENAME",
                                  tokenDescription: "FileInfo.Hint.Tokens.Filename.Description")
                AvailableTokenRow(tokenName: "SPLITFRONT",
                                  tokenDescription: "FileInfo.Hint.Tokens.SplitFront.Description")
                AvailableTokenRow(tokenName: "SPLITBACK",
                                  tokenDescription: "FileInfo.Hint.Tokens.SplitBack.Description")
            } header: {
                VStack(alignment: .leading, spacing: 2.0) {
                    ListSectionHeader(text: "FileInfo.Hint.Tokens.Title")
                        .font(.body)
                }
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
                .transition(AnyTransition.scale.animation(.snappy))
            }
        }
        .onAppear {
            readAllTagData()
        }
        .onChange(of: selectedAlbumArt, initial: false) {
            Task {
                if let selectedAlbumArt = selectedAlbumArt,
                    let data = try? await selectedAlbumArt.loadTransferable(type: Data.self) {
                    tagData.albumArt = data
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
    // swiftlint:disable function_body_length
    // TODO: Optimize this function
    func readAllTagData() {
        debugPrint("Attempting to read tag data for \(files.count) files...")

        // Check for common tag data betwen all files
        var albumArt: Data?
        var title, artist, album, albumArtist, genre, composer: String?
        var year, track, discNumber: Int?
        for index in 0..<files.count {
            debugPrint("Attempting to read tag data for file \(index)...")
            do {
                let tag = try id3TagEditor.read(from: files[index].path)
                if let tag = tag {
                    tags.updateValue(tag, forKey: files[index])
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
        tagData.albumArt = albumArt
        tagData.title = title ?? ""
        tagData.artist = artist ?? ""
        tagData.album = album ?? ""
        tagData.albumArtist = albumArtist ?? ""
        if let year = year { tagData.year = String(year) }
        if let track = track { tagData.track = String(track) }
        tagData.genre = genre ?? ""
        tagData.composer = composer ?? ""
        if let discNumber = discNumber { tagData.discNumber = String(discNumber) }
    }
    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable function_body_length

    func saveAllTagData() {
        for file in files {
            saveTagData(to: file)
        }
    }

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    // TODO: Optimize this function
    func saveTagData(to file: FSFile, retriesWhenFailed willRetry: Bool = true) {
        debugPrint("Attempting to save tag data...")
        changeSaveState(to: .saving)
        do {
            let tag = tags[file]
            var tagBuilder = ID32v3TagBuilder()
            // Build title frame
            if let frame = id3Frame(tagData.title, returns: ID3FrameWithStringContent.self, referencing: file) {
                tagBuilder = tagBuilder.title(frame: frame)
            } else if let tag = tag, let value = ID3TagContentReader(id3Tag: tag).title() {
                tagBuilder = tagBuilder.title(frame: id3Frame(value, referencing: file))
            }
            // Build artist frame
            if let frame = id3Frame(tagData.artist, returns: ID3FrameWithStringContent.self, referencing: file) {
                tagBuilder = tagBuilder.artist(frame: frame)
            } else if let tag = tag, let value = ID3TagContentReader(id3Tag: tag).artist() {
                tagBuilder = tagBuilder.artist(frame: id3Frame(value, referencing: file))
            }
            // Build album frame
            if let frame = id3Frame(tagData.album, returns: ID3FrameWithStringContent.self, referencing: file) {
                tagBuilder = tagBuilder.album(frame: frame)
            } else if let tag = tag, let value = ID3TagContentReader(id3Tag: tag).album() {
                tagBuilder = tagBuilder.album(frame: id3Frame(value, referencing: file))
            }
            // Build album artist frame
            if let frame = id3Frame(tagData.albumArtist, returns: ID3FrameWithStringContent.self, referencing: file) {
                tagBuilder = tagBuilder.albumArtist(frame: frame)
            } else if let tag = tag, let value = ID3TagContentReader(id3Tag: tag).albumArtist() {
                tagBuilder = tagBuilder.albumArtist(frame: id3Frame(value, referencing: file))
            }
            // Build year frame
            if let frame = id3Frame(tagData.year, returns: ID3FrameWithIntegerContent.self) {
                tagBuilder = tagBuilder.recordingYear(frame: frame)
            } else if let tag = tag, let value = ID3TagContentReader(id3Tag: tag).recordingYear() {
                tagBuilder = tagBuilder.recordingYear(frame: ID3FrameWithIntegerContent(value: value))
            }
            // Build track frame
            if let frame = id3Frame(tagData.track, returns: ID3FramePartOfTotal.self) {
                tagBuilder = tagBuilder.trackPosition(frame: frame)
            } else if let tag = tag, let value = ID3TagContentReader(id3Tag: tag).trackPosition() {
                tagBuilder = tagBuilder.trackPosition(frame: id3Frame(value.position, total: value.total))
            }
            // Build genre frame
            if let frame = id3Frame(tagData.genre, returns: ID3FrameGenre.self) {
                tagBuilder = tagBuilder.genre(frame: frame)
            } else if let tag = tag, let value = ID3TagContentReader(id3Tag: tag).genre(),
                      let description = value.description {
                tagBuilder = tagBuilder.genre(frame: id3Frame(description, identifier: value.identifier))
            }
            // Build composer frame
            if let frame = id3Frame(tagData.composer, returns: ID3FrameWithStringContent.self, referencing: file) {
                tagBuilder = tagBuilder.albumArtist(frame: frame)
            } else if let tag = tag, let value = ID3TagContentReader(id3Tag: tag).composer() {
                tagBuilder = tagBuilder.composer(frame: id3Frame(value, referencing: file))
            }
            // Build disc number frame
            if let frame = id3Frame(tagData.discNumber, returns: ID3FramePartOfTotal.self) {
                tagBuilder = tagBuilder.discPosition(frame: frame)
            } else if let tag = tag, let value = ID3TagContentReader(id3Tag: tag).discPosition() {
                tagBuilder = tagBuilder.discPosition(frame: id3Frame(value.position, total: value.total))
            }
            // Build album art frame
            if let frame = id3Frame(tagData.albumArt, type: .frontCover) {
                tagBuilder = tagBuilder.attachedPicture(pictureType: .frontCover, frame: frame)
            } else if let tag = tag, let albumArt = ID3TagContentReader(id3Tag: tag).attachedPictures()
                .first(where: { $0.type == .frontCover }),
                      let frame = id3Frame(albumArt.picture, type: .frontCover) {
                tagBuilder = tagBuilder
                    .attachedPicture(pictureType: .frontCover, frame: frame)
            }
            try id3TagEditor.write(tag: tagBuilder.build(), to: file.path)
            changeSaveState(to: .saved)
        } catch {
            debugPrint("Error occurred while saving tag: \n\(error.localizedDescription)")
            if willRetry {
                initializeTag(for: file)
                saveTagData(to: file, retriesWhenFailed: false)
            } else {
                changeSaveState(to: .notSaved)
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable function_body_length

    func initializeTag(for file: FSFile) {
        debugPrint("Attempting to initialize tag...")
        do {
            let id3Tag = ID32v3TagBuilder()
                .title(frame: ID3FrameWithStringContent(content: ""))
                .build()
            try id3TagEditor.write(tag: id3Tag, to: file.path)
        } catch {
            debugPrint("Error occurred while initializing tag: \n\(error.localizedDescription)")
        }
    }

    func id3Frame<T>(_ value: String,
                     returns type: T.Type,
                     referencing file: FSFile? = nil) -> T? {
        switch type {
        case is ID3FrameWithStringContent.Type:
            if value != "" {
                if let file = file {
                    return ID3FrameWithStringContent(content: replaceTokens(value, file: file)) as? T
                } else {
                    return ID3FrameWithStringContent(content: value) as? T
                }
            }
        case is ID3FrameWithIntegerContent.Type:
            if value != "", let int = Int(value) {
                return ID3FrameWithIntegerContent(value: int) as? T
            }
        case is ID3FramePartOfTotal.Type:
            if value != "", let int = Int(value) {
                return ID3FramePartOfTotal(part: int, total: nil) as? T
            }
        case is ID3FrameGenre.Type:
            if value != "" {
                return ID3FrameGenre(genre: nil, description: value) as? T
            }
        default: break
        }
        return nil
    }

    func id3Frame(_ value: String,
                  referencing file: FSFile?) -> ID3FrameWithStringContent {
        if let file = file {
            return ID3FrameWithStringContent(content: replaceTokens(value, file: file))
        } else {
            return ID3FrameWithStringContent(content: value)
        }
    }

    func id3Frame(_ value: Int, total: Int?) -> ID3FramePartOfTotal {
        return ID3FramePartOfTotal(part: value, total: total)
    }

    func id3Frame(_ value: String, identifier: ID3Genre?) -> ID3FrameGenre {
        return ID3FrameGenre(genre: identifier, description: value)
    }

    func id3Frame(_ data: Data?, type: ID3PictureType) -> ID3FrameAttachedPicture? {
        if let data = data,
           let image = UIImage(data: data) {
            if let pngData = image.pngData() {
                return ID3FrameAttachedPicture(picture: pngData,
                                               type: type,
                                               format: .png)
            } else if let jpgData = image.jpegData(compressionQuality: 1.0) {
                return ID3FrameAttachedPicture(picture: jpgData,
                                               type: type,
                                               format: .jpeg)
            }
        }
        return nil
    }

    func replaceTokens(_ original: String, file: FSFile) -> String {
        var processedString = original
        let componentsSplitByDash = file.name
            .replacingOccurrences(of: ".mp3",
                                  with: "")
            .components(separatedBy: " - ")
        if componentsSplitByDash.count >= 1 {
            processedString = processedString
                .replacingOccurrences(of: "%SPLITFRONT%",
                                      with: componentsSplitByDash[0])
        } else {
            processedString = processedString
                .replacingOccurrences(of: "%SPLITFRONT%",
                                      with: "")
        }
        if componentsSplitByDash.count >= 2 {
            processedString = processedString
                .replacingOccurrences(of: "%SPLITBACK%",
                                      with: componentsSplitByDash[1])
        } else {
            processedString = processedString
                .replacingOccurrences(of: "%SPLITBACK%",
                                      with: "")
        }
        processedString =  processedString
            .replacingOccurrences(of: "%filename%",
                                  with: file.name.replacingOccurrences(of: ".mp3", with: ""),
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
