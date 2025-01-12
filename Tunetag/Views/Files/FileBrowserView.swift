//
//  FileBrowserView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import Komponents
import SwiftUI
import TipKit

struct FileBrowserView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var fileManager: FilesystemManager
    @EnvironmentObject var batchFileManager: BatchFileManager
    @State var currentDirectory: FSDirectory?
    @State var files: [any FilesystemObject] = []
    @State var tagEditorFile: FSFile?
    @State var addToQueueState: SaveState = .notSaved
    @State var isInitialLoadCompleted: Bool = false

    // Support for iOS 16
    @State var showsLegacyTip: Bool = true

    var body: some View {
        NavigationStack(path: $navigationManager.browserTabPath) {
            List {
                if #unavailable(iOS 17.0) {
                    TipSection(title: "FileBrowser.Tip.NoFiles.Title",
                               message: "FileBrowser.Tip.NoFiles.Text",
                               image: Image(systemName: "questionmark.folder.fill"),
                               showsTip: $showsLegacyTip)
                }
                Section {
                    ForEach($files, id: \.path) { $file in
                        if let directory = file as? FSDirectory {
                            NavigationLink(value: ViewPath.fileBrowser(directory: directory)) {
                                ListFolderRow(name: directory.name)
                            }
                            .contextMenu(menuItems: {
                                Button {
                                    addToQueue(directory: directory)
                                } label: {
                                    Label("Shared.AddFiles", systemImage: "folder.fill.badge.plus")
                                }
                                Button {
                                    addToQueue(directory: directory, recursively: true)
                                } label: {
                                    Label("Shared.AddFilesRecursively", systemImage: "folder.fill.badge.plus")
                                }
                            })
                        } else if let file = file as? FSFile {
                            Button {
                                tagEditorFile = file
                            } label: {
                                ListFileRow(name: file.name, icon: Image("File.MP3"))
                            }
                            .tint(.primary)
                            .draggable(file) {
                                ListFileRow(name: file.name, icon: Image("File.MP3"))
                                    .padding()
                                    .background(.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 10.0))
                            }
                            .contextMenu(menuItems: {
                                Button {
                                    addToQueue(file: file)
                                } label: {
                                    Label("Shared.AddFile", systemImage: "doc.fill.badge.plus")
                                }
                            }, preview: {
                                FilePreview(file: file)
                            })
                        }
                    }
                } header: {
                    Text(verbatim: "")
                }
                if files.contains(where: { file in
                    if let file = file as? FSFile {
                        let url = URL(filePath: file.path)
                        return url.pathExtension.lowercased() == "mp3"
                    }
                    return false
                }) {
                    Section {
                        HStack(alignment: .center, spacing: 0.0) {
                            Spacer(minLength: 0.0)
                            Button {
                                if addToQueueState == .notSaved {
                                    if let currentDirectory = currentDirectory {
                                        addToQueue(directory: currentDirectory)
                                    } else {
                                        addToQueue(
                                            directory: FSDirectory(
                                                name: "Documents",
                                                path: FileManager.default.urls(
                                                    for: .documentDirectory,
                                                    in: .userDomainMask).first!.path,
                                                files: []
                                            )
                                        )
                                    }
                                    withAnimation(.snappy.speed(2)) {
                                        addToQueueState = .saved
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        withAnimation(.snappy.speed(2)) {
                                            addToQueueState = .notSaved
                                        }
                                    }
                                }
                            } label: {
                                HStack(alignment: .center, spacing: 0.0) {
                                    switch addToQueueState {
                                    case .saved:
                                        Image(systemName: "checkmark")
                                    default:
                                        HStack(alignment: .center, spacing: 4.0) {
                                            Image(systemName: "plus.square.fill.on.square.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 18.0, height: 18.0)
                                            Text("FileBrowser.AddFiles")
                                                .bold()
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .frame(minHeight: 24.0)
                            }
                            .buttonStyle(.borderedProminent)
                            .clipShape(RoundedRectangle(cornerRadius: 99))
                            Spacer(minLength: 0.0)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .fileBrowser(let directory): FileBrowserView(currentDirectory: directory)
                default: Color.clear
                }
            })
            .refreshable {
                refreshFiles()
            }
            .background {
                if files.count == 0 && isInitialLoadCompleted {
                    VStack {
                        HintOverlay(image: "questionmark.folder", text: "FileBrowser.Hint")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if currentDirectory == nil {
                        if #available(iOS 17.0, *) {
                            openFilesAppButton()
                                .popoverTip(FileBrowserNoFilesTip())
                        } else {
                            openFilesAppButton()
                        }
                    } else {
                        Color.clear
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                DropZone()
                    .opacity(0)
            }
            .sheet(item: $tagEditorFile, content: { file in
                NavigationStack {
                    TagEditorView(files: [file])
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                CloseButton {
                                    tagEditorFile = nil
                                }
                            }
                        }
                }
                .interactiveDismissDisabled()
            })
            .navigationTitle(currentDirectory != nil ?
                             currentDirectory!.name :
                                NSLocalizedString("ViewTitle.Files", comment: ""))
        }
        .onAppear {
            showsLegacyTip = !UserDefaults.standard.bool(forKey: "LegacyTipsHidden.FileBrowserNoFilesTip")
            refreshFiles()
        }
        .onChange(of: showsLegacyTip) { _ in
            UserDefaults.standard.setValue(!showsLegacyTip, forKey: "LegacyTipsHidden.FileBrowserNoFilesTip")
        }
    }

    func refreshFiles() {
        withAnimation {
            files = fileManager.files(in: currentDirectory?.path ?? "")
                .sorted(by: { lhs, rhs in
                    lhs.name < rhs.name
                })
                .sorted(by: { lhs, rhs in
                    return lhs is FSDirectory && rhs is FSFile
                })
            isInitialLoadCompleted = true
        }
    }

    func addToQueue(directory: FSDirectory, recursively isRecursiveAdd: Bool = false) {
        let contents = fileManager.files(in: directory.path)
        var files: [FSFile] = []
        for content in contents {
            if let file = content as? FSFile {
                files.append(file)
            }
        }
        files.sort(by: { $0.name < $1.name })
        batchFileManager.addFiles(files)
        if isRecursiveAdd {
            for content in contents {
                if let directory = content as? FSDirectory {
                    addToQueue(directory: directory, recursively: isRecursiveAdd)
                }
            }
        }
    }

    func addToQueue(file: FSFile) {
        if !batchFileManager.files.contains(file) {
            batchFileManager.addFile(file)
        }
    }

    @ViewBuilder
    func openFilesAppButton() -> some View {
        Button {
            let documentsUrl = FileManager.default.urls(for: .documentDirectory,
                                                        in: .userDomainMask).first!
#if targetEnvironment(macCatalyst)
            UIApplication.shared.open(documentsUrl)
#else
            if let sharedUrl = URL(string: "shareddocuments://\(documentsUrl.path)") {
                if UIApplication.shared.canOpenURL(sharedUrl) {
                    UIApplication.shared.open(sharedUrl)
                }
            }
#endif
        } label: {
            HStack(alignment: .center, spacing: 8.0) {
#if targetEnvironment(macCatalyst)
                Image("SystemApps.Finder")
                    .resizable()
                    .frame(width: 30.0, height: 30.0)
#else
                Image("SystemApps.Files")
                    .resizable()
                    .frame(width: 30.0, height: 30.0)
                    .clipShape(RoundedRectangle(cornerRadius: 6.0))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6.0)
                            .stroke(.black, lineWidth: 1/3)
                            .opacity(0.3)
                    }
#endif
                Text("Shared.OpenFilesApp")
            }
        }
    }
}
