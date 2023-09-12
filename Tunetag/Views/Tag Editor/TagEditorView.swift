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

    let id3TagEditor = ID3TagEditor()
    @State var files: [FSFile]
    @State var tags: [FSFile: ID3Tag] = [:]
    @State var tagData = Tag()
    @State var selectedAlbumArt: PhotosPickerItem?
    @State var saveState: SaveState = .notSaved
    @FocusState var focusedField: FocusedField?

    // Support for iOS 16
    @State var showsLegacyTip: Bool = true

    var body: some View {
        List {
            if #unavailable(iOS 17.0) {
                TipSection(title: "TagEditor.Tip.Tokens.Title",
                           message: "TagEditor.Tip.Tokens.Text",
                           image: Image(systemName: "info.circle.fill"),
                           showsTip: $showsLegacyTip)
            }
            if files.count == 1 {
                FileHeaderSection(filename: files[0].name,
                                  albumArt: $tagData.albumArt,
                                  selectedAlbumArt: $selectedAlbumArt)
                if #available(iOS 17.0, *) {
                    TagDataSection(tagData: $tagData, focusedField: $focusedField)
                        .popoverTip(AvailableTokensTip(), arrowEdge: .top)
                } else {
                    TagDataSection(tagData: $tagData, focusedField: $focusedField)
                }
            } else {
                FileHeaderSection(filename: NSLocalizedString("BatchEdit.MultipleFiles", comment: ""),
                                  albumArt: $tagData.albumArt,
                                  selectedAlbumArt: $selectedAlbumArt)
                if #available(iOS 17.0, *) {
                    TagDataSection(tagData: $tagData, focusedField: $focusedField,
                                   placeholder: NSLocalizedString("BatchEdit.Keep", comment: ""))
                    .popoverTip(AvailableTokensTip(), arrowEdge: .top)
                } else {
                    TagDataSection(tagData: $tagData, focusedField: $focusedField,
                                   placeholder: NSLocalizedString("BatchEdit.Keep", comment: ""))
                }
            }
            Section {
                AvailableTokenRow(tokenName: "FILENAME", tokenDescription: "TagEditor.Tokens.Filename.Description")
                AvailableTokenRow(tokenName: "SPLITFRONT", tokenDescription: "TagEditor.Tokens.SplitFront.Description")
                AvailableTokenRow(tokenName: "SPLITBACK", tokenDescription: "TagEditor.Tokens.SplitBack.Description")
            } header: {
                VStack(alignment: .leading, spacing: 2.0) {
                    ListSectionHeader(text: "TagEditor.Tokens.Title")
                        .font(.body)
                }
            }
        }
        .disabled(saveState == .saving)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                if saveState == .notSaved {
                    DispatchQueue.global(qos: .background).async {
                        Task {
                            changeSaveState(to: .saving)
                            await saveAllTagData()
                            await readAllTagData()
                            changeSaveState(to: .saved)
                        }
                    }
                }
            } label: {
                switch saveState {
                case .notSaved:
                    LargeButtonLabel(iconName: "square.and.arrow.down.fill", text: "Shared.Save")
                        .bold()
                        .frame(maxWidth: .infinity)
                case .saving:
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding(.all, 8.0)
                        .tint(.white)
                case .saved:
                    Image(systemName: "checkmark")
                        .font(.body)
                        .bold()
                        .padding([.top, .bottom], 8.0)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(saveState == .saved ? .green : .accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 99))
            .frame(minHeight: 56.0)
            .padding([.leading, .trailing, .bottom])
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Shared.Done") {
                    focusedField = nil
                }
                .bold()
            }
        }
        .task {
            showsLegacyTip = !UserDefaults.standard.bool(forKey: "LegacyTipsHidden.AvailableTokensTip")
            await readAllTagData()
        }
        .onChange(of: showsLegacyTip) { _ in
            UserDefaults.standard.setValue(!showsLegacyTip, forKey: "LegacyTipsHidden.AvailableTokensTip")
        }
        .onChange(of: selectedAlbumArt, perform: { _ in
            Task {
                if let selectedAlbumArt = selectedAlbumArt,
                    let data = try? await selectedAlbumArt.loadTransferable(type: Data.self) {
                    tagData.albumArt = data
                }
            }
        })
        .onChange(of: saveState, perform: { _ in
            switch saveState {
            case .saved:
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    changeSaveState(to: .notSaved)
                }
            default:
                break
            }
        })
    }

    func readAllTagData() async {
        debugPrint("Attempting to read tag data for \(files.count) files...")
        // Check for common tag data betwen all files
        var tagCombined: TagTyped?
        for file in files {
            debugPrint("Attempting to read tag data for file \(file.name)...")
            do {
                let tag = try id3TagEditor.read(from: file.path)
                if let tag = tag {
                    tags.updateValue(tag, forKey: file)
                    let tagContentReader = ID3TagContentReader(id3Tag: tag)
                    if tagCombined == nil {
                        tagCombined = await TagTyped(file, reader: tagContentReader)
                    } else {
                        await tagCombined!.merge(with: file, reader: tagContentReader)
                    }
                }
            } catch {
                debugPrint("Error occurred while reading tags: \n\(error.localizedDescription)")
            }
        }
        // Load data into view
        if let tagCombined = tagCombined {
            tagData = Tag(from: tagCombined)
        }
    }

    func saveAllTagData() async {
        _ = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for file in files {
                group.addTask {
                    return saveTagData(to: file)
                }
            }

            var saveStates: [Bool] = []
            for await result in group {
                saveStates.append(result)
            }
            return saveStates
        }
        // TODO: Report status of save
    }

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    func saveTagData(to file: FSFile, retriesWhenFailed willRetry: Bool = true) -> Bool {
        debugPrint("Attempting to save tag data...")
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
            return true
        } catch {
            debugPrint("Error occurred while saving tag: \n\(error.localizedDescription)")
            if willRetry {
                initializeTag(for: file)
                return saveTagData(to: file, retriesWhenFailed: false)
            } else {
                return false
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
        var newString = original
        let componentsDash = file.name
            .replacingOccurrences(of: ".mp3", with: "")
            .components(separatedBy: "-").map { string in
            string.trimmingCharacters(in: .whitespaces)
        }
        let tokens: [String: String] = [
            "fileName": file.name,
            "splitFront": componentsDash[0],
            "splitBack": componentsDash.count >= 2 ? componentsDash[1] : "",
        ]
        for (key, value) in tokens {
            newString = newString.replacingOccurrences(of: "%\(key)%", with: value, options: .caseInsensitive)
        }
        return newString
    }

    func changeSaveState(to newState: SaveState) {
        withAnimation(.snappy.speed(2)) {
            saveState = newState
        }
    }

}
// swiftlint:enable type_body_length
