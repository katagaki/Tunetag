//
//  BatchEditView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import SwiftUI

struct BatchEditView: View {

    @State var files: [FSFile] = []

    var body: some View {
        NavigationStack {
            List(files, id: \.path) { file in
                ListFileRow(name: file.name)
            }
            .listStyle(.plain)
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
                        // TODO: Present editor
                    } label: {
                        LargeButtonLabel(iconName: "pencil",
                                         text: "BatchEdit.StartEditing")
                        .bold()
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(RoundedRectangle(cornerRadius: 99))
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
            .navigationTitle("ViewTitle.BatchEdit")
        }
    }

}
