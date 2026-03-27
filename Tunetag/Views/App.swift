//
//  TunetagApp.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import SwiftUI

@main
struct TunetagApp: App {

    // Kept to satisfy environment object requirements in legacy views still in the project
    @StateObject var tabManager = TabManager()
    @StateObject var navigationManager = NavigationManager()
    @StateObject var fileManager = FilesystemManager()
    @StateObject var batchFileManager = BatchFileManager()

    @State var editorFiles: [FSFile] = []
    @State var isTagEditorPresented: Bool = false
    @State var isMorePresented: Bool = false

    var body: some Scene {
        WindowGroup {
            DocumentBrowserContainerView(
                onFilesOpened: { urls in
                    let files = urls.compactMap { url -> FSFile? in
                        guard url.pathExtension.lowercased() == "mp3" else { return nil }
                        _ = url.startAccessingSecurityScopedResource()
                        return FSFile(name: url.lastPathComponent,
                                     path: url.path(percentEncoded: false),
                                     isArbitrarilyLoadedFromDragAndDrop: true)
                    }
                    guard !files.isEmpty else { return }
                    editorFiles = files
                    isTagEditorPresented = true
                },
                onMoreTapped: {
                    isMorePresented = true
                }
            )
            .sheet(isPresented: $isTagEditorPresented, onDismiss: {
                editorFiles.forEach { file in
                    URL(filePath: file.path).stopAccessingSecurityScopedResource()
                }
                editorFiles = []
            }) {
                NavigationStack {
                    TagEditorView(files: editorFiles)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    isTagEditorPresented = false
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.footnote.weight(.bold))
                                        .padding(7)
                                        .background(Color(.systemFill), in: Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                }
                .interactiveDismissDisabled()
            }
            .sheet(isPresented: $isMorePresented, onDismiss: {
                navigationManager.moreTabPath = []
            }) {
                MoreView()
                    .environmentObject(navigationManager)
            }
            .environmentObject(tabManager)
            .environmentObject(navigationManager)
            .environmentObject(fileManager)
            .environmentObject(batchFileManager)
        }
    }
}
