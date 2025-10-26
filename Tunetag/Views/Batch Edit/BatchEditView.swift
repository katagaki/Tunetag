//
//  BatchEditView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import Komponents
import SwiftUI
import UniformTypeIdentifiers

struct BatchEditView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var batchFileManager: BatchFileManager
    @State var isInteractiveHelpPresenting: Bool = false
    @State var isFolderPickerPresenting: Bool = false

    var body: some View {
        NavigationStack(path: $navigationManager.batchEditTabPath) {
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0.0) {
                    ForEach(batchFileManager.files, id: \.path) { file in
                        HStack {
                            ListFileRow(name: file.name, icon: Image("File.MP3"))
                                .frame(minHeight: 43)
                            Spacer()
                            Button {
                                withAnimation(.snappy.speed(2)) {
                                    URL(filePath: file.path).stopAccessingSecurityScopedResource()
                                    batchFileManager.files.removeAll(where: { $0.id == file.id })
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding([.leading, .trailing], 20.0)
                        Divider()
                            .padding(.leading, 64.0)
                    }
                }
            }
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .tagEditorMultiple: TagEditorView(files: batchFileManager.files)
                default: Color.clear
                }
            })
            .overlay {
                if batchFileManager.files.isEmpty {
                    VStack(alignment: .center, spacing: 16.0) {
                        HintOverlay(image: "questionmark.folder", text: "BatchEdit.Hint")
                        Button {
                            isFolderPickerPresenting = true
                        } label: {
                            Text("BatchEdit.SelectFiles")
                                .bold()
                        }
                        .buttonStyle(.borderedProminent)
                        .clipShape(RoundedRectangle(cornerRadius: 99))
                        Button {
                            isInteractiveHelpPresenting = true
                        } label: {
                            Text("Shared.LearnHow")
                                .bold()
                        }
                        .buttonStyle(.borderedProminent)
                        .clipShape(RoundedRectangle(cornerRadius: 99))
                    }
                }
            }
            .sheet(isPresented: $isInteractiveHelpPresenting, content: {
                BatchEditInteractiveHelpView()
            })
            .sheet(isPresented: $isFolderPickerPresenting, content: {
                FolderPicker(isPresented: $isFolderPickerPresenting) { urls in
                    handleSelectedFiles(urls)
                }
                .ignoresSafeArea()
            })
            .safeAreaInset(edge: .bottom) {
                Button {
                    navigationManager.push(ViewPath.tagEditorMultiple,
                                           for: .batchEdit)
                } label: {
                    LargeButtonLabel(iconName: "pencil",
                                     text: "BatchEdit.StartEditing")
                    .bold()
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 99))
                .frame(minHeight: 56.0)
                .padding([.leading, .trailing, .bottom])
                .disabled(batchFileManager.files.isEmpty)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !batchFileManager.files.isEmpty {
                        Button {
                            withAnimation(.snappy.speed(2)) {
                                batchFileManager.files.removeAll()
                            }
                        } label: {
                            Text("Shared.ClearAll")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("ViewTitle.BatchEditor")
        }
    }

    func handleSelectedFiles(_ urls: [URL]) {
        for url in urls {
            if url.hasDirectoryPath {
                // Handle folder
                addFilesFromFolder(url)
            } else if url.pathExtension.lowercased() == "mp3" {
                // Handle individual file
                _ = url.startAccessingSecurityScopedResource()
                let file = FSFile(name: url.lastPathComponent,
                                path: url.path(percentEncoded: false),
                                isArbitrarilyLoadedFromDragAndDrop: true)
                addFile(file)
            }
        }
    }
    
    func addFilesFromFolder(_ folderUrl: URL) {
        _ = folderUrl.startAccessingSecurityScopedResource()
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(at: folderUrl,
                                                               includingPropertiesForKeys: [.isRegularFileKey],
                                                               options: [.skipsHiddenFiles])
            for fileUrl in contents {
                if fileUrl.pathExtension.lowercased() == "mp3" {
                    _ = fileUrl.startAccessingSecurityScopedResource()
                    let file = FSFile(name: fileUrl.lastPathComponent,
                                    path: fileUrl.path(percentEncoded: false),
                                    isArbitrarilyLoadedFromDragAndDrop: true)
                    addFile(file)
                }
            }
        } catch {
            debugPrint("Error reading folder contents: \(error.localizedDescription)")
        }
    }

    func addFile(_ file: FSFile) {
        DispatchQueue.main.async {
            withAnimation(.snappy.speed(2)) {
                batchFileManager.addFile(file)
            }
        }
    }
}
