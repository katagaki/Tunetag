//
//  ListFileRow.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import SwiftUI

struct ListFileRow: View {

    var name: String
    var icon: Image

    var body: some View {
        HStack(alignment: .center, spacing: 16.0) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 24.0, height: 24.0)
            Text(name)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

}
