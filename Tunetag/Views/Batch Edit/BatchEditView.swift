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

    var body: some View {
        NavigationStack(path: $navigationManager.batchEditTabPath) {
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0.0) {
                    ForEach(batchFileManager.files, id: \.path) { file in
                        ListFileRow(name: file.name, icon: Image("File.MP3"))
                            .frame(minHeight: 43)
                            .padding([.leading, .trailing], 20.0)
                        Divider()
                            .padding(.leading, 64.0)
                    }
                    .onDelete { indexSet in
                        // TODO: Migrate to new method of deletion (button?)
                        batchFileManager.files.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .tagEditorMultiple: TagEditorView(files: batchFileManager.files)
                default: Color.clear
                }
            })
            .onDrop(of: [.mp3], isTargeted: $isDropZoneTarget) { items in
                debugPrint(items.count)
                // TODO: Test with slow network share
                for item in items {
                    item.loadInPlaceFileRepresentation(
                        forTypeIdentifier: UTType.mp3.identifier) { url, _, _ in
                        if let url = url {
                            DispatchQueue.main.async {
                                batchFileManager.addFile(FSFile(name: url.lastPathComponent,
                                                                path: url.path(percentEncoded: false),
                                                                isArbitrarilyLoadedFromDragAndDrop: true))
                            }
                        }
                    }
                }
                return true
            }
            .dropDestination(for: FSFile.self) { items, _ in
                batchFileManager.addFiles(items)
                return true
            }
            .background {
                if batchFileManager.files.isEmpty {
                    VStack(alignment: .center, spacing: 0.0) {
                        HintOverlay(image: "questionmark.folder", text: "BatchEdit.Hint")
                        Button {
                            // TODO: Show video tutorial
                        } label: {
                            Text("Shared.LearnHow")
                        }
                        .buttonStyle(.bordered)
                    }
                }
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !batchFileManager.files.isEmpty {
                        Button {
                            batchFileManager.files.removeAll()
                        } label: {
                            Text("Shared.ClearAll")
                        }
                    }
                }
            }
            .navigationTitle("ViewTitle.BatchEditor")
        }
    }

}
