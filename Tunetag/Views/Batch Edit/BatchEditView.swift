//
//  BatchEditView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import SwiftUI

struct BatchEditView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var batchFileManager: BatchFileManager

    var body: some View {
        NavigationStack(path: $navigationManager.batchEditTabPath) {
            List {
                ForEach(batchFileManager.files, id: \.path) { file in
                    ListFileRow(name: file.name)
                }
                .onDelete { indexSet in
                    batchFileManager.files.remove(atOffsets: indexSet)
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .tagEditorMultiple:
                    TagEditorView(files: batchFileManager.files)
                default:
                    Color.clear
                }
            })
            .background {
                if batchFileManager.files.isEmpty {
                    ListHintOverlay(image: "questionmark.folder", text: "BatchEdit.Hint")
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .center, spacing: 16.0) {
                    VStack(alignment: .center, spacing: 16.0) {
                        Image(systemName: "square.and.arrow.down.on.square.fill")
                            .font(.largeTitle)
                        Text("BatchEdit.DropZone.Hint")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10.0))
                    .padding([.leading, .trailing])
                    .dropDestination(for: FSFile.self) { items, _ in
                        for item in items where !batchFileManager.files.contains(item) {
                            batchFileManager.files.append(contentsOf: items)
                        }
                        return true
                    }
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
                    .padding([.leading, .trailing, .bottom])
                    .disabled(batchFileManager.files.isEmpty)
                }
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
            .navigationTitle("ViewTitle.BatchEdit")
        }
    }

}
