//
//  FileBrowserView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import SwiftUI

struct FileBrowserView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var fileManager: FilesystemManager
    @State var currentDirectory: FSDirectory?
    @State var files: [any FilesystemObject] = []

    var body: some View {
        NavigationStack(path: $navigationManager.browserTabPath) {
            List($files, id: \.path) { $file in
                if let directory = file as? FSDirectory {
                    NavigationLink(value: ViewPath.fileBrowser(directory: directory)) {
                        HStack(alignment: .center, spacing: 8.0) {
                            Image(systemName: "folder")
                            Text(file.name)
                                .font(.body)
                        }
                    }
                } else if let file = file as? FSFile {
                    NavigationLink(value: ViewPath.fileInfo(file: file)) {
                        HStack(alignment: .center, spacing: 8.0) {
                            Image(systemName: "doc")
                            Text(file.name)
                                .font(.body)
                        }
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
                    ListHintOverlay(image: "questionmark.folder",
                                    text: "FileBrowser.Hint")
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
