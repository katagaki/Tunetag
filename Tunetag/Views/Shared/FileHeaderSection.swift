//
//  FileHeaderSection.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import PhotosUI
import SwiftUI

struct FileHeaderSection: View {

    @State var filename: String
    @Binding var albumArt: Data?
    @Binding var selectedAlbumArt: PhotosPickerItem?
    @State var showsPhotosPicker: Bool = true

    var body: some View {
        Section {
            HStack(alignment: .center, spacing: 8.0) {
                Group {
                    if let albumArt = albumArt,
                       let albumArtImage = UIImage(data: albumArt) {
                        Image(uiImage: albumArtImage)
                            .resizable()
                    } else {
                        Image(.albumGeneric)
                            .resizable()
                    }
                }
                .scaledToFill()
                .frame(width: 100.0, height: 100.0)
                .clipShape(RoundedRectangle(cornerRadius: 10.0))
                .overlay(
                    RoundedRectangle(cornerRadius: 10.0)
                        .stroke(.primary, lineWidth: 1/3)
                        .opacity(0.3)
                )
                .overlay {
                    if showsPhotosPicker {
                        PhotosPicker(selection: $selectedAlbumArt,
                                     matching: .images,
                                     photoLibrary: .shared()) {
                            Image(systemName: "pencil")
                        }
                        .clipShape(Circle())
                        .buttonStyle(.borderedProminent)
                    }
                }
                Text(filename)
                    .bold()
                    .textCase(.none)
                    .foregroundStyle(.primary)
            }
            .listRowBackground(Color.clear)
        }
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}
