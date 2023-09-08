//
//  BatchEditView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import SwiftUI

struct BatchEditView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @State var files: [FSFile] = []

    var body: some View {
        NavigationStack(path: $navigationManager.batchEditTabPath) {
            List {
                ForEach(files, id: \.path) { file in
                    ListFileRow(name: file.name)
                }
                .onDelete { indexSet in
                    files.remove(atOffsets: indexSet)
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .batchFileInfo(let files):
                    BatchFileInfoView(files: files)
                default:
                    Color.clear
                }
            })
            .overlay {
                if files.isEmpty {
                    ListHintOverlay(image: "questionmark.folder", text: "BatchEdit.Hint")
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .center, spacing: 16.0) {
                    Image(systemName: "square.and.arrow.down.on.square.fill")
                        .font(.largeTitle)
                    Text("BatchEdit.DropZone.Hint")
                    Button {
                        navigationManager.push(ViewPath.batchFileInfo(files: files),
                                               for: .batchEdit)
                    } label: {
                        LargeButtonLabel(iconName: "pencil",
                                         text: "BatchEdit.StartEditing")
                        .bold()
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(RoundedRectangle(cornerRadius: 99))
                    .disabled(files.isEmpty)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10.0))
                .padding()
                .dropDestination(for: FSFile.self) { items, _ in
                    for item in items where !files.contains(item) {
                        files.append(contentsOf: items)
                    }
                    return true
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !files.isEmpty {
                        Button {
                            files.removeAll()
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
