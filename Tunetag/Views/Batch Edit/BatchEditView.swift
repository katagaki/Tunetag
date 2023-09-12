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
                    ListFileRow(name: file.name, icon: Image("File.MP3"))
                }
                .onDelete { indexSet in
                    batchFileManager.files.remove(atOffsets: indexSet)
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .tagEditorMultiple: TagEditorView(files: batchFileManager.files)
                default: Color.clear
                }
            })
            .background {
                if batchFileManager.files.isEmpty {
                    ListHintOverlay(image: "questionmark.folder", text: "BatchEdit.Hint")
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
