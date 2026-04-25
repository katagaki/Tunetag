//
//  TagEditorView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import Komponents
import PhotosUI
import SFBAudioEngine
import SwiftUI
import TipKit

struct TagEditorView: View {

    @State var files: [FSFile]
    @State var audioFiles: [FSFile: AudioFile] = [:]
    @State var tagData = Tag()
    @State var selectedAlbumArt: PhotosPickerItem?
    @State var isAlbumArtRemoved: Bool = false
    @State var saveState: SaveState = .notSaved
    @State var savedFileCount: Int = 0
    @State var totalFileCount: Int = 0
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
                                  selectedAlbumArt: $selectedAlbumArt,
                                  isAlbumArtRemoved: $isAlbumArtRemoved)
                if #available(iOS 17.0, *) {
                    TagDataSection(tagData: $tagData, focusedField: $focusedField)
                        .popoverTip(AvailableTokensTip(), arrowEdge: .top)
                } else {
                    TagDataSection(tagData: $tagData, focusedField: $focusedField)
                }
            } else {
                FileHeaderSection(filename: NSLocalizedString("BatchEdit.MultipleFiles", comment: ""),
                                  albumArt: $tagData.albumArt,
                                  selectedAlbumArt: $selectedAlbumArt,
                                  isAlbumArtRemoved: $isAlbumArtRemoved)
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
                }
            }
        }
        .disabled(saveState == .saving)
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                if saveState == .notSaved {
                    DispatchQueue.global(qos: .background).async {
                        Task {
                            await changeSaveState(to: .saving)
                            await saveAllTagData()
                            await readAllTagData()
                            await changeSaveState(to: .saved)
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
                    if totalFileCount > 1 {
                        VStack(spacing: 4.0) {
                            ProgressView(value: Double(savedFileCount),
                                         total: Double(max(totalFileCount, 1)))
                                .progressViewStyle(.linear)
                                .tint(.white)
                            Text("\(savedFileCount) / \(totalFileCount)")
                                .font(.caption)
                                .bold()
                                .foregroundStyle(.white)
                                .monospacedDigit()
                        }
                        .padding([.top, .bottom], 8.0)
                        .padding([.leading, .trailing], 16.0)
                        .frame(maxWidth: .infinity)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .padding(.all, 8.0)
                            .tint(.white)
                    }
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
            .modifier(SaveButtonStyleModifier())
            .frame(minHeight: 56.0)
            .padding([.leading, .trailing, .bottom])
        }
        .task {
            showsLegacyTip = !UserDefaults.standard.bool(forKey: "LegacyTipsHidden.AvailableTokensTip")
            await readAllTagData()
        }
        .onChange(of: showsLegacyTip) { _, _ in
            UserDefaults.standard.setValue(!showsLegacyTip, forKey: "LegacyTipsHidden.AvailableTokensTip")
        }
        .onChange(of: selectedAlbumArt) { _, _ in
            Task {
                if let selectedAlbumArt = selectedAlbumArt,
                    let data = try? await selectedAlbumArt.loadTransferable(type: Data.self) {
                    tagData.albumArt = data
                    isAlbumArtRemoved = false
                }
            }
        }
        .onChange(of: saveState) { _, _ in
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

    func readAllTagData() async {
        debugPrint("Attempting to read tag data for \(files.count) files...")
        var tagCombined: TagTyped?
        var loadedAudioFiles: [FSFile: AudioFile] = [:]
        for file in files {
            debugPrint("Attempting to read tag data for file \(file.name)...")
            do {
                let url = URL(filePath: file.path)
                let audioFile = try AudioFile(readingPropertiesAndMetadataFrom: url)
                loadedAudioFiles[file] = audioFile
                let metadata = audioFile.metadata
                if tagCombined == nil {
                    tagCombined = TagTyped(file, metadata: metadata)
                } else {
                    tagCombined!.merge(with: file, metadata: metadata)
                }
            } catch {
                debugPrint("Error occurred while reading tags: \n\(error.localizedDescription)")
            }
        }
        audioFiles = loadedAudioFiles
        if let tagCombined = tagCombined {
            tagData = Tag(from: tagCombined)
        }
        isAlbumArtRemoved = false
    }

    func saveAllTagData() async {
        await MainActor.run {
            withAnimation(.snappy.speed(2)) {
                savedFileCount = 0
                totalFileCount = files.count
            }
        }
        _ = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for file in files {
                group.addTask {
                    return await saveTagData(to: file)
                }
            }

            var saveStates: [Bool] = []
            for await result in group {
                saveStates.append(result)
                await MainActor.run {
                    withAnimation(.snappy.speed(2)) {
                        savedFileCount += 1
                    }
                }
            }
            return saveStates
        }
    }

    func saveTagData(to file: FSFile) -> Bool {
        debugPrint("Attempting to save tag data...")
        do {
            let url = URL(filePath: file.path)
            let audioFile = audioFiles[file] ?? (try AudioFile(readingPropertiesAndMetadataFrom: url))
            let metadata = audioFile.metadata
            applyEdits(to: metadata, for: file)
            try audioFile.writeMetadata()
            return true
        } catch {
            debugPrint("Error occurred while saving tag: \n\(error.localizedDescription)")
            return false
        }
    }

    private func applyEdits(to metadata: AudioMetadata, for file: FSFile) {
        if let title = tagData.title {
            metadata.title = replaceTokens(title, file: file)
        }
        if let artist = tagData.artist {
            metadata.artist = replaceTokens(artist, file: file)
        }
        if let album = tagData.album {
            metadata.albumTitle = replaceTokens(album, file: file)
        }
        if let albumArtist = tagData.albumArtist {
            metadata.albumArtist = replaceTokens(albumArtist, file: file)
        }
        if let year = tagData.year {
            metadata.releaseDate = year.isEmpty ? nil : year
        }
        if let track = tagData.track {
            metadata.trackNumber = track.isEmpty ? nil : Int(track)
        }
        if let genre = tagData.genre {
            metadata.genre = genre.isEmpty ? nil : genre
        }
        if let composer = tagData.composer {
            metadata.composer = replaceTokens(composer, file: file)
        }
        if let discNumber = tagData.discNumber {
            metadata.discNumber = discNumber.isEmpty ? nil : Int(discNumber)
        }
        applyAlbumArtEdits(to: metadata)
    }

    private func applyAlbumArtEdits(to metadata: AudioMetadata) {
        if let newArtData = tagData.albumArt,
           let sanitized = sanitizedImageData(newArtData) {
            metadata.removeAttachedPicturesOfType(.frontCover)
            metadata.attachPicture(AttachedPicture(imageData: sanitized, type: .frontCover))
        } else if isAlbumArtRemoved {
            metadata.removeAttachedPicturesOfType(.frontCover)
        }
    }

    private func sanitizedImageData(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        if let pngData = image.pngData() {
            return pngData
        }
        return image.jpegData(compressionQuality: 1.0)
    }

    func replaceTokens(_ original: String, file: FSFile) -> String {
        var newString = original
        let nameWithoutExtension = (file.name as NSString).deletingPathExtension
        let componentsDash = nameWithoutExtension
            .components(separatedBy: "-").map { string in
                string.trimmingCharacters(in: .whitespaces)
            }
        let tokens: [String: String] = [
            "fileName": nameWithoutExtension,
            "splitFront": componentsDash[0],
            "splitBack": componentsDash.count >= 2 ? componentsDash[1] : ""
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

struct SaveButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive())
        } else {
            content
                .clipShape(RoundedRectangle(cornerRadius: 99))
        }
    }
}
