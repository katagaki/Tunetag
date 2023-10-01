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
    @State var isDropZoneTarget: Bool = false
    @State var isInteractiveHelpPresenting: Bool = false

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
                    VStack(alignment: .center, spacing: 0.0) {
                        HintOverlay(image: "questionmark.folder", text: "BatchEdit.Hint")
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
            .onDrop(of: [.mp3, .fileURL], isTargeted: $isDropZoneTarget) { items in
                for item in items {
                    debugPrint("Attempting to open in place...")
                    getFile(item, for: UTType.mp3.identifier) { file in
                        if let file = file {
                            addFile(file)
                        } else {
                            debugPrint("Attempting to open in place (strategy #2)...")
                            _ = getFile(item) { file in
                                if let file = file {
                                    addFile(file)
                                }
                            }
                        }
                    }
                }
                return true
            }
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
            .sheet(isPresented: $isInteractiveHelpPresenting, content: {
                BatchEditInteractiveHelpView()
            })
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

    func addFile(_ file: FSFile) {
        DispatchQueue.main.async {
            withAnimation(.snappy.speed(2)) {
                batchFileManager.addFile(file)
            }
        }
    }

    func getFile(_ item: NSItemProvider, for type: String, completion: @escaping (FSFile?) -> Void) {
        item.loadInPlaceFileRepresentation(forTypeIdentifier: type) { url, _, error in
            if let url = url {
                completion(FSFile(name: url.lastPathComponent,
                                  path: url.path(percentEncoded: false),
                                  isArbitrarilyLoadedFromDragAndDrop: true))
            } else if let error = error {
                debugPrint(error.localizedDescription)
            }
            completion(nil)
        }
    }

    func getFile(_ item: NSItemProvider, completion: @escaping (FSFile?) -> Void) -> Progress {
        return item.loadFileRepresentation(for: .mp3, openInPlace: true) { url, _, error in
            if let url = url {
                _ = url.startAccessingSecurityScopedResource()
                completion(FSFile(name: url.lastPathComponent,
                                  path: url.path(percentEncoded: false),
                                  isArbitrarilyLoadedFromDragAndDrop: true))
            } else if let error = error {
                debugPrint(error.localizedDescription)
            }
            completion(nil)
        }
    }
}
