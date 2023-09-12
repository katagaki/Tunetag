//
//  DropZone.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/10.
//

import SwiftUI

struct DropZone: View {

    @EnvironmentObject var batchFileManager: BatchFileManager

    var body: some View {
        VStack(alignment: .center, spacing: 16.0) {
            Image("DropZone.Icon")
            Text("FileBrowser.DropZone.Hint.Simple")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .overlay(Rectangle().frame(width: nil,
                                    height: 1/3,
                                    alignment: .top).foregroundColor(.primary.opacity(0.3)),
                 alignment: .top)
        .dropDestination(for: FSFile.self) { items, _ in
            batchFileManager.addFiles(items)
            return true
        }
    }
}
