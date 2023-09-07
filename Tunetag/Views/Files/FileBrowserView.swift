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
                    NavigationLink(value: ViewPath.fileInfo(file: file)) {
                        ListFileRow(name: file.name)
                    }
                    .draggable(file) {
                        ListFileRow(name: file.name)
                    }
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .fileBrowser(let directory):
                    FileBrowserView(currentDirectory: directory)
                case .fileInfo(let file):
                    FileInfoView(currentFile: file)
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
                        TipView(noFilesTip, arrowEdge: .bottom)
                            .padding()
                        ListHintOverlay(image: "questionmark.folder",
                                        text: "FileBrowser.Hint")
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
