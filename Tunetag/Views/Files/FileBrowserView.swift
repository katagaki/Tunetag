//
//  FileBrowserView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import SwiftUI
import TipKit
import ZIPFoundation

struct FileBrowserView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var fileManager: FilesystemManager
    @EnvironmentObject var batchFileManager: BatchFileManager
    @State var currentDirectory: FSDirectory?
    @State var files: [any FilesystemObject] = []

    @State var extractionProgress: Progress?
    @State var isExtractingZIP: Bool = false
    @State var extractionPercentage: Int = 0
    @State var isExtractionCancelling: Bool = false
    @State var isErrorAlertPresenting: Bool = false
    @State var errorText: String = ""

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
                ForEach($files, id: \.path) { $file in
                    if let directory = file as? FSDirectory {
                        NavigationLink(value: ViewPath.fileBrowser(directory: directory)) {
                            ListFolderRow(name: directory.name)
                        }
                        .contextMenu(menuItems: {
                            Button {
                                navigationManager.push(ViewPath.fileBrowser(directory: directory), for: .fileManager)
                            } label: {
                                Label("Shared.Open", systemImage: "folder.fill")
                            }
                            ControlGroup {
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
                            } label: {
                                Text("Shared.BatchEditor")
                            }
                            .controlGroupStyle(.menu)
                        }, preview: {
                            NavigationStack {
                                VStack(alignment: .center, spacing: 16.0) {
                                    Image("Folder")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 64.0, height: 64.0)
                                    Text(directory.name)
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                }
                                .padding()
                            }
                        })
                    } else if let file = file as? FSFile {
                        switch file.filetype {
                        case .mp3:
                            Button {
                                navigationManager.push(ViewPath.tagEditorSingle(file: file), for: .fileManager)
                            } label: {
                                ListFileRow(name: file.name, icon: file.filetype.icon())
                            }
                            .draggable(file) {
                                ListFileRow(name: file.name, icon: file.filetype.icon())
                                    .padding()
                                    .background(.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 10.0))
                            }
                            .contextMenu(menuItems: {
                                Button {
                                    navigationManager.push(ViewPath.tagEditorSingle(file: file), for: .fileManager)
                                } label: {
                                    Label("Shared.Edit", systemImage: "pencil")
                                }
                                ControlGroup {
                                    Button {
                                        addToQueue(file: file)
                                    } label: {
                                        Label("Shared.AddFile", systemImage: "doc.fill.badge.plus")
                                    }
                                } label: {
                                    Text("Shared.BatchEditor")
                                }
                                .controlGroupStyle(.menu)
                            }, preview: {
                                FilePreview(file: file)
                            })
                        case .zip:
                            Button {
                                extractFiles(file: file)
                            } label: {
                                ListFileRow(name: file.name, icon: file.filetype.icon())
                            }
                            .contextMenu(menuItems: {
                                Button {
                                    extractFiles(file: file)
                                } label: {
                                    Label("Shared.Extract", systemImage: "doc.zipper")
                                }
                            }, preview: {
                                NavigationStack {
                                    VStack(alignment: .center, spacing: 16.0) {
                                        file.filetype.icon()
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 64.0, height: 64.0)
                                        Text(file.name)
                                            .bold()
                                            .frame(maxWidth: .infinity)
                                    }
                                    .padding()
                                }
                            })
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .fileBrowser(let directory): FileBrowserView(currentDirectory: directory)
                case .tagEditorSingle(let file): TagEditorView(files: [file])
                default: Color.clear
                }
            })
            .refreshable {
                refreshFiles()
            }
            .background {
                if files.count == 0 {
                    VStack {
                        ListHintOverlay(image: "questionmark.folder",
                                        text: "FileBrowser.Hint")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if currentDirectory == nil {
                        if #available(iOS 17.0, *) {
                            openFilesAppButton()
                                .popoverTip(FileBrowserNoFilesTip())
                        } else {
                            openFilesAppButton()
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                DropZone()
            }
            .overlay {
                if isExtractingZIP {
                    ProgressAlert(title: "Alert.ExtractingZIP.Title",
                                  message: "Alert.ExtractingZIP.Text",
                                  percentage: $extractionPercentage) {
                        withAnimation(.easeOut.speed(2)) {
                            isExtractionCancelling = true
                            extractionProgress?.cancel()
                            extractionPercentage = 0
                            isExtractingZIP = false
                        }
                    }
                }
            }
            .alert(Text("Alert.ExtractingZIP.Error.Title"),
                   isPresented: $isErrorAlertPresenting,
                   actions: {
                Button("Shared.OK", role: .cancel) { }
            },
                   message: {
                Text(verbatim: errorText)
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
        }
    }

    func extractFiles(file: FSFile, encoding: String.Encoding = .shiftJIS) {
        withAnimation(.easeOut.speed(2)) {
            isExtractingZIP = true
        }
        let destinationURL = URL(filePath: file.path).deletingPathExtension()
        let destinationDirectory = destinationURL.path().removingPercentEncoding ?? destinationURL.path()
        debugPrint("Attempting to create directory \(destinationDirectory)...")
        fileManager.createDirectory(at: destinationDirectory)
        debugPrint("Attempting to extract ZIP to \(destinationDirectory)...")
        extractionProgress = Progress()
        DispatchQueue.global(qos: .background).async {
            let observation = extractionProgress?.observe(\.fractionCompleted) { progress, _ in
                DispatchQueue.main.async {
                    extractionPercentage = Int(progress.fractionCompleted * 100)
                }
            }
            do {
                try FileManager().unzipItem(at: URL(filePath: file.path),
                                            to: URL(filePath: destinationDirectory),
                                            skipCRC32: true,
                                            progress: extractionProgress,
                                            preferredEncoding: encoding)
                DispatchQueue.main.async {
                    withAnimation(.easeOut.speed(2)) {
                        isExtractingZIP = false
                    }
                    refreshFiles()
                }
            } catch {
                if !isExtractionCancelling {
                    debugPrint("Error occurred while extracting ZIP: \(error.localizedDescription)")
                    if encoding == .shiftJIS {
                        debugPrint("Attempting extraction with UTF-8...")
                        extractFiles(file: file, encoding: .utf8)
                    } else {
                        DispatchQueue.main.async {
                            errorText = error.localizedDescription
                            withAnimation(.easeOut.speed(2)) {
                                isExtractingZIP = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isErrorAlertPresenting = true
                            }
                        }
                    }
                } else {
                    isExtractionCancelling = false
                }
            }
            observation?.invalidate()
        }
    }

    func addToQueue(directory: FSDirectory, recursively isRecursiveAdd: Bool = false) {
        let contents = fileManager.files(in: directory.path)
        var files: [FSFile] = []
        for content in contents {
            if let file = content as? FSFile,
               file.filetype == .mp3 {
                files.append(file)
            }
        }
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
        batchFileManager.addFile(file)
    }

    @ViewBuilder
    func openFilesAppButton() -> some View {
        Button {
            let documentsUrl = FileManager.default.urls(for: .documentDirectory,
                                                        in: .userDomainMask).first!
            if let sharedUrl = URL(string: "shareddocuments://\(documentsUrl.path)") {
                if UIApplication.shared.canOpenURL(sharedUrl) {
                    UIApplication.shared.open(sharedUrl, options: [:])
                }
            }
        } label: {
            HStack(alignment: .center, spacing: 8.0) {
                Image("SystemApps.Files")
                    .resizable()
                    .frame(width: 30.0, height: 30.0)
                    .clipShape(RoundedRectangle(cornerRadius: 6.0))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6.0)
                            .stroke(.black, lineWidth: 1/3)
                            .opacity(0.3)
                    }
                Text("Shared.OpenFilesApp")
            }
        }
    }
}
