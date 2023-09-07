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
        HStack(alignment: .center, spacing: 8.0) {
            Image(systemName: "folder.fill")
            Text(name)
                .font(.body)
        }
    }

}
