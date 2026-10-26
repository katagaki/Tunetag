//
//  TagEditorView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import PhotosUI
import Prelude
import SwiftUI
import TipKit

struct TagEditorView: View {

    @State var files: [FSFile]
    @State var tagData = Tag()
    @State var loadedTagData = Tag()
    @State var selectedAlbumArt: PhotosPickerItem?
    @State var isAlbumArtRemoved: Bool = false
    @State var saveState: SaveState = .notSaved
    @State var savedFileCount: Int = 0
    @State var totalFileCount: Int = 0
    @State var isReadingTags: Bool = true
    @State var showsSaveError: Bool = false
    @State var isSortingExpanded: Bool = false
    @State var showsExtendedTags: Bool = false
    @State var showsSaveBeforeExtendedTags: Bool = false
    @State var showsRemoveTagsConfirmation: Bool = false
    @State var showsRemoveTagsError: Bool = false
    @State var isSidebarShown: Bool = false
    @FocusState var focusedField: FocusedField?

    // Support for iOS 16
    @State var showsLegacyTip: Bool = true

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var usesWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        editorContent
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
            // While typing, the keyboard bar takes the place of the Save button
            if focusedField != nil {
                keyboardBar
                    .padding([.leading, .trailing, .bottom])
            } else if !(usesWideLayout && isSidebarShown) {
                saveControls
                    .frame(maxWidth: usesWideLayout ? 480.0 : .infinity)
                    .padding([.leading, .trailing, .bottom])
            }
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
        .alert("TagEditor.SaveFailed.Message", isPresented: $showsSaveError) {
            Button("Shared.OK", role: .cancel) { }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                moreMenu
            }
        }
        .navigationDestination(isPresented: $showsExtendedTags) {
            ExtendedTagsView(file: files[0]) {
                Task { await readAllTagData() }
            }
        }
        .alert("TagEditor.ExtendedTags.SaveFirst", isPresented: $showsSaveBeforeExtendedTags) {
            Button("Shared.OK", role: .cancel) { }
        }
        .confirmationDialog("TagEditor.RemoveAllTags.Confirm", isPresented: $showsRemoveTagsConfirmation,
                            titleVisibility: .visible) {
            Button("TagEditor.RemoveAllTags", role: .destructive) {
                Task { await removeAllTagsFromFiles() }
            }
        }
        .alert("TagEditor.RemoveAllTags.Failed", isPresented: $showsRemoveTagsError) {
            Button("Shared.OK", role: .cancel) { }
        }
    }

    @ViewBuilder
    var editorContent: some View {
        if usesWideLayout {
            TagEditorWideLayout(tagData: $tagData, focusedField: $focusedField,
                                isBatchEditing: files.count > 1, showsAdvancedInformation: files.count == 1,
                                isSortingExpanded: $isSortingExpanded,
                                isSidebarShown: $isSidebarShown) {
                FileHeaderView(filename: filename,
                               albumArt: $tagData.albumArt,
                               selectedAlbumArt: $selectedAlbumArt,
                               isAlbumArtRemoved: $isAlbumArtRemoved)
                .frame(maxWidth: .infinity)
            } sidebarFooter: {
                saveControls
            }
        } else {
            List {
                if #unavailable(iOS 17.0) {
                    TipSection(title: "TagEditor.Tip.Tokens.Title",
                               message: "TagEditor.Tip.Tokens.Text",
                               image: Image(systemName: "info.circle.fill"),
                               showsTip: $showsLegacyTip)
                    .editorRowBackground()
                }
                FileHeaderSection(filename: filename,
                                  albumArt: $tagData.albumArt,
                                  selectedAlbumArt: $selectedAlbumArt,
                                  isAlbumArtRemoved: $isAlbumArtRemoved)
                TagDataSection(tagData: $tagData, focusedField: $focusedField,
                               isBatchEditing: files.count > 1, isSortingExpanded: $isSortingExpanded)
                .editorRowBackground()
                if files.count == 1 {
                    TagInfoSection(tagData: tagData)
                        .editorRowBackground()
                }
            }
            .editorListBackground()
        }
    }

    var saveControls: some View {
        VStack(spacing: 4) {
            if !tagData.hasValidNumbers {
                Text("TagEditor.InvalidNumber.Message")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            Button {
                if saveState == .notSaved && !isReadingTags {
                    Task {
                        changeSaveState(to: .saving)
                        UIApplication.shared.isIdleTimerDisabled = true
                        let allSaved = await saveAllTagData()
                        await readAllTagData()
                        UIApplication.shared.isIdleTimerDisabled = false
                        changeSaveState(to: allSaved ? .saved : .notSaved)
                        showsSaveError = !allSaved
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
        }
        .disabled(isReadingTags || !tagData.hasValidNumbers)
    }

    var filename: String {
        files.count == 1 ? files[0].name : NSLocalizedString("BatchEdit.MultipleFiles", comment: "")
    }

    var moreMenu: some View {
        Menu {
            if files.count == 1 {
                Button("TagEditor.ExtendedTags", systemImage: "list.bullet.rectangle") {
                    if hasUnsavedChanges {
                        showsSaveBeforeExtendedTags = true
                    } else {
                        showsExtendedTags = true
                    }
                }
            }
            Button("TagEditor.RemoveAllTags", systemImage: "trash", role: .destructive) {
                showsRemoveTagsConfirmation = true
            }
        } label: {
            Label("TagEditor.MoreActions", systemImage: "ellipsis")
        }
        .disabled(saveState == .saving || isReadingTags)
    }

    var hasUnsavedChanges: Bool {
        tagData != loadedTagData || isAlbumArtRemoved
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

extension TagEditorView {

    var keyboardBar: some View {
        HStack {
            if files.count > 1, let field = focusedField {
                // Puts a field back to keeping each file's own value
                Button("BatchEdit.DontChange") {
                    tagData[keyPath: field.keyPath] = nil
                }
                .disabled(tagData[keyPath: field.keyPath] == nil)
            }
            Spacer()
            Button("Shared.DismissKeyboard", systemImage: "keyboard.chevron.compact.down") {
                focusedField = nil
            }
            .labelStyle(.iconOnly)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
    }
}
