//
//  ListFolderRow.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import SwiftUI

struct ListFolderRow: View {

    var name: String

    var body: some View {
        HStack(alignment: .center, spacing: 16.0) {
            Image("Folder")
                .resizable()
                .scaledToFit()
                .frame(width: 28.0, height: 28.0)
            Text(name)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

}
