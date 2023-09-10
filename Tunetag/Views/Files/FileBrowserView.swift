//
//  FileBrowserView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import SwiftUI
import TipKit

struct FileBrowserView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var fileManager: FilesystemManager
    @EnvironmentObject var batchFileManager: BatchFileManager
    @State var currentDirectory: FSDirectory?
    @State var files: [any FilesystemObject] = []

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
                                navigationManager.push(ViewPath.fileBrowser(directory: directory),
                                                       for: .fileManager)
                            } label: {
                                Label("Shared.Open", systemImage: "folder.fill")
                            }
                        })
                    } else if let file = file as? FSFile {
                        Button {
                            navigationManager.push(ViewPath.tagEditorSingle(file: file),
                                                   for: .fileManager)
                        } label: {
                            ListFileRow(name: file.name)
                        }
                        .draggable(file) {
                            ListFileRow(name: file.name)
                                .padding()
                                .background(.background)
                                .clipShape(RoundedRectangle(cornerRadius: 10.0))
                        }
                        .contextMenu(menuItems: {
                            Button {
                                navigationManager.push(ViewPath.tagEditorSingle(file: file),
                                                       for: .fileManager)
                            } label: {
                                Label("Shared.Edit", systemImage: "pencil")
                            }
                        }, preview: {
                            FilePreview(file: file)
                        })
                    }
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .fileBrowser(let directory):
                    FileBrowserView(currentDirectory: directory)
                case .tagEditorSingle(let file):
                    TagEditorView(files: [file])
                default:
                    Color.clear
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
                    if #available(iOS 17.0, *) {
                        openFilesAppButton()
                            .popoverTip(FileBrowserNoFilesTip())
                    } else {
                        openFilesAppButton()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .center, spacing: 16.0) {
                    Image(systemName: "square.and.arrow.down.on.square.fill")
                        .font(.largeTitle)
                    Text("BatchEdit.DropZone.Hint.Simple")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10.0))
                .padding()
                .dropDestination(for: FSFile.self) { items, _ in
                    for item in items where !batchFileManager.files.contains(item) {
                        batchFileManager.files.append(contentsOf: items)
                    }
                    return true
                }
            }
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
        files = fileManager.files(in: currentDirectory?.path ?? "")
            .sorted(by: { lhs, rhs in
                lhs.name < rhs.name
            })
            .sorted(by: { lhs, rhs in
                return lhs is FSDirectory && rhs is FSFile
            })
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
