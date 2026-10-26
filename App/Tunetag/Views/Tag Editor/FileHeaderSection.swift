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
    @Binding var isAlbumArtRemoved: Bool
    @State var showsPhotosPicker: Bool = true

    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        Section {
            Group {
                if verticalSizeClass == .compact {
                    // Landscape on iPhone: keep the header short so the fields stay visible
                    HStack(alignment: .center, spacing: 16.0) {
                        albumArtView(size: 96.0)
                        details(alignment: .leading)
                    }
                } else {
                    VStack(alignment: .center, spacing: 16.0) {
                        albumArtView(size: 180.0)
                        details(alignment: .center)
                    }
                }
            }
            .listRowBackground(Color.clear)
            .frame(maxWidth: .infinity)
        }
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }

    func albumArtView(size: CGFloat) -> some View {
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
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10.0))
        .overlay(
            RoundedRectangle(cornerRadius: 10.0)
                .stroke(.primary, lineWidth: 1/3)
                .opacity(0.3)
        )
    }

    func details(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 8.0) {
            Text(filename)
                .bold()
                .textCase(.none)
                .foregroundStyle(.primary)
                .multilineTextAlignment(alignment == .leading ? .leading : .center)
            if showsPhotosPicker {
                HStack(spacing: 8.0) {
                    PhotosPicker(selection: $selectedAlbumArt,
                                 matching: .images,
                                 photoLibrary: .shared()) {
                        Text("TagEditor.SelectAlbumArt")
                            .bold()
                    }
                                 .clipShape(RoundedRectangle(cornerRadius: 99))
                                 .buttonStyle(.borderedProminent)
                    if albumArt != nil {
                        Button(role: .destructive) {
                            selectedAlbumArt = nil
                            albumArt = nil
                            isAlbumArtRemoved = true
                        } label: {
                            Label("TagEditor.RemoveAlbumArt", systemImage: "trash")
                                .labelStyle(.iconOnly)
                                .bold()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 99))
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
            }
        }
    }
}
