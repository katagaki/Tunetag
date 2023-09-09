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

    var noFilesTip = FileBrowserNoFilesTip()

    var body: some View {
        NavigationStack(path: $navigationManager.browserTabPath) {
            List($files, id: \.path) { $file in
                if let directory = file as? FSDirectory {
                    NavigationLink(value: ViewPath.fileBrowser(directory: directory)) {
                        ListFolderRow(name: directory.name)
                    }
                } else if let file = file as? FSFile {
                    Button {
                        navigationManager.push(ViewPath.fileInfo(file: file),
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
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .fileBrowser(let directory):
                    FileBrowserView(currentDirectory: directory)
                case .fileInfo(let file):
                    TagEditorView(files: [file])
                default:
                    Color.clear
                }
            })
            .refreshable {
                refreshFiles()
            }
            .overlay {
                if files.count == 0 {
                    VStack {
                        ListHintOverlay(image: "questionmark.folder",
                                        text: "FileBrowser.Hint")
                        .popoverTip(noFilesTip)
                    }
                    .task {
                        // Configure and load your tips at app launch.
                        try? Tips.configure([
                            .displayFrequency(.immediate),
                            .datastoreLocation(.applicationDefault)
                        ])
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
            refreshFiles()
        }
    }

    func refreshFiles() {
        files = fileManager.files(in: currentDirectory?.path ?? "")
            .sorted(by: { lhs, rhs in
                lhs.name < rhs.name
            })
            .sorted(by: { lhs, _ in
                // swiftlint:disable unused_optional_binding
                if let _ = lhs as? FSDirectory {
                    return true
                }
                // swiftlint:enable unused_optional_binding
                return false
            })
    }
}
