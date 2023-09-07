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
            Image(systemName: "folder.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 24.0, height: 24.0)
                .foregroundStyle(.cyan)
            Text(name)
                .font(.body)
        }
    }

}
