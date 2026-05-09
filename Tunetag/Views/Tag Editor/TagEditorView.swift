//
//  TagEditorView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

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
    @State var isReadingTags: Bool = true
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
        .disabled(saveState == .saving || isReadingTags)
        .overlay {
            if isReadingTags {
                ZStack {
                    Color(.systemBackground).opacity(0.6)
                    ProgressView()
                        .controlSize(.large)
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                if saveState == .notSaved && !isReadingTags {
                    Task {
                        changeSaveState(to: .saving)
                        UIApplication.shared.isIdleTimerDisabled = true
                        await saveAllTagData()
                        await readAllTagData()
                        UIApplication.shared.isIdleTimerDisabled = false
                        changeSaveState(to: .saved)
                    }
                }
            } label: {
                switch saveState {
                case .notSaved:
                    LargeButtonLabel(iconName: "square.and.arrow.down.fill", text: "Shared.Save")
                        .bold()
                        .frame(maxWidth: .infinity)
                case .saving:
                    ProgressDonut(progress: totalFileCount > 0
                                  ? Double(savedFileCount) / Double(totalFileCount)
                                  : 0)
                        .frame(width: 24.0, height: 24.0)
                        .padding(.all, 8.0)
                case .saved:
                    Image(systemName: "checkmark")
                        .font(.body)
                        .bold()
                        .padding([.top, .bottom], 8.0)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(tintForSaveState)
            .modifier(SaveButtonStyleModifier())
            .frame(minHeight: 56.0)
            .padding([.leading, .trailing, .bottom])
            .disabled(isReadingTags)
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
        await MainActor.run {
            withAnimation(.snappy.speed(2)) {
                isReadingTags = true
            }
        }
        let filesToRead = files
        let result = await Task.detached(priority: .userInitiated) {
            () -> (audioFiles: [FSFile: AudioFile], tagCombined: TagTyped?) in
            debugPrint("Attempting to read tag data for \(filesToRead.count) files...")
            var tagCombined: TagTyped?
            var loadedAudioFiles: [FSFile: AudioFile] = [:]
            for file in filesToRead {
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
            return (loadedAudioFiles, tagCombined)
        }.value

        await MainActor.run {
            audioFiles = result.audioFiles
            if let tagCombined = result.tagCombined {
                tagData = Tag(from: tagCombined)
            }
            isAlbumArtRemoved = false
            withAnimation(.snappy.speed(2)) {
                isReadingTags = false
            }
        }
    }

    func saveAllTagData() async {
        await MainActor.run {
            withAnimation(.snappy.speed(2)) {
                savedFileCount = 0
                totalFileCount = files.count
            }
        }
        let filesToSave = files
        let cachedAudioFiles = audioFiles
        let tagSnapshot = tagData
        let albumArtRemoved = isAlbumArtRemoved

        let maxConcurrentSaves = 4
        await withTaskGroup(of: Bool.self) { group in
            var iterator = filesToSave.makeIterator()

            func addNext() -> Bool {
                guard let file = iterator.next() else { return false }
                let cached = cachedAudioFiles[file]
                group.addTask(priority: .userInitiated) {
                    return await Self.saveTagData(to: file,
                                                  cached: cached,
                                                  tag: tagSnapshot,
                                                  albumArtRemoved: albumArtRemoved)
                }
                return true
            }

            for _ in 0..<maxConcurrentSaves {
                if !addNext() { break }
            }

            while await group.next() != nil {
                await MainActor.run {
                    withAnimation(.snappy.speed(2)) {
                        savedFileCount += 1
                    }
                }
                _ = addNext()
            }
        }
    }

    nonisolated static func saveTagData(to file: FSFile,
                                        cached: AudioFile?,
                                        tag: Tag,
                                        albumArtRemoved: Bool) async -> Bool {
        return await Task.detached(priority: .userInitiated) {
            debugPrint("Attempting to save tag data...")
            do {
                let url = URL(filePath: file.path)
                let audioFile: AudioFile
                if let cached {
                    audioFile = cached
                } else {
                    audioFile = try AudioFile(readingPropertiesAndMetadataFrom: url)
                }
                let metadata = audioFile.metadata
                applyEdits(to: metadata, file: file, tag: tag, albumArtRemoved: albumArtRemoved)
                try audioFile.writeMetadata()
                return true
            } catch {
                debugPrint("Error occurred while saving tag: \n\(error.localizedDescription)")
                return false
            }
        }.value
    }

    nonisolated private static func applyEdits(to metadata: AudioMetadata,
                                               file: FSFile,
                                               tag: Tag,
                                               albumArtRemoved: Bool) {
        if let title = tag.title {
            metadata.title = replaceTokens(title, file: file)
        }
        if let artist = tag.artist {
            metadata.artist = replaceTokens(artist, file: file)
        }
        if let album = tag.album {
            metadata.albumTitle = replaceTokens(album, file: file)
        }
        if let albumArtist = tag.albumArtist {
            metadata.albumArtist = replaceTokens(albumArtist, file: file)
        }
        if let year = tag.year {
            metadata.releaseDate = year.isEmpty ? nil : year
        }
        if let track = tag.track {
            metadata.trackNumber = track.isEmpty ? nil : Int(track)
        }
        if let genre = tag.genre {
            metadata.genre = genre.isEmpty ? nil : genre
        }
        if let composer = tag.composer {
            metadata.composer = replaceTokens(composer, file: file)
        }
        if let discNumber = tag.discNumber {
            metadata.discNumber = discNumber.isEmpty ? nil : Int(discNumber)
        }
        applyAlbumArtEdits(to: metadata, tag: tag, albumArtRemoved: albumArtRemoved)
    }

    nonisolated private static func applyAlbumArtEdits(to metadata: AudioMetadata,
                                                       tag: Tag,
                                                       albumArtRemoved: Bool) {
        if let newArtData = tag.albumArt,
           let sanitized = sanitizedImageData(newArtData) {
            metadata.removeAttachedPicturesOfType(.frontCover)
            metadata.attachPicture(AttachedPicture(imageData: sanitized, type: .frontCover))
        } else if albumArtRemoved {
            metadata.removeAttachedPicturesOfType(.frontCover)
        }
    }

    nonisolated private static func sanitizedImageData(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        if let pngData = image.pngData() {
            return pngData
        }
        return image.jpegData(compressionQuality: 1.0)
    }

    nonisolated static func replaceTokens(_ original: String, file: FSFile) -> String {
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

    var tintForSaveState: Color {
        switch saveState {
        case .notSaved: return .accentColor
        case .saving: return .orange
        case .saved: return .green
        }
    }

}

struct ProgressDonut: View {
    var progress: Double
    var lineWidth: CGFloat = 3.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(Color.white,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
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
