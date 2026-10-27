//
//  FileHeaderSection.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct FileHeaderSection: View {

    var filename: String
    @Binding var albumArt: Data?
    @Binding var selectedAlbumArt: PhotosPickerItem?
    @Binding var isAlbumArtRemoved: Bool

    var body: some View {
        Section {
            FileHeaderView(filename: filename,
                           albumArt: $albumArt,
                           selectedAlbumArt: $selectedAlbumArt,
                           isAlbumArtRemoved: $isAlbumArtRemoved)
            .listRowBackground(Color.clear)
            .frame(maxWidth: .infinity)
        }
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

struct FileHeaderView: View {

    var filename: String
    @Binding var albumArt: Data?
    @Binding var selectedAlbumArt: PhotosPickerItem?
    @Binding var isAlbumArtRemoved: Bool

    @State var showsPhotosPicker: Bool = false
    @State var showsFileImporter: Bool = false

    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        HStack(alignment: .center, spacing: 16.0) {
            // Landscape on iPhone: keep the header short so the fields stay visible
            albumArtView(size: verticalSizeClass == .compact ? 80.0 : 112.0)
            details
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .photosPicker(isPresented: $showsPhotosPicker,
                      selection: $selectedAlbumArt,
                      matching: .images,
                      photoLibrary: .shared())
        .fileImporter(isPresented: $showsFileImporter,
                      allowedContentTypes: [.image]) { result in
            if case .success(let url) = result {
                loadAlbumArt(from: url)
            }
        }
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

    var details: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Text(filename)
                .font(.title3)
                .fontWeight(.bold)
                .textCase(.none)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .truncationMode(.middle)
            HStack(spacing: 8.0) {
                Menu {
                    Button("TagEditor.AlbumArt.Photos", systemImage: "photo.on.rectangle") {
                        showsPhotosPicker = true
                    }
                    Button("TagEditor.AlbumArt.Files", systemImage: "folder") {
                        showsFileImporter = true
                    }
                } label: {
                    Text(albumArt != nil ? LocalizedStringKey("TagEditor.AlbumArt.Edit")
                                         : LocalizedStringKey("TagEditor.AlbumArt.Add"))
                        .bold()
                }
                .clipShape(RoundedRectangle(cornerRadius: 99))
                .buttonStyle(.borderedProminent)
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
                .disabled(albumArt == nil)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func loadAlbumArt(from url: URL) {
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        guard let data = try? Data(contentsOf: url),
              UIImage(data: data) != nil else { return }
        // Clears the Photos selection so picking the same photo again is still seen as a change
        selectedAlbumArt = nil
        albumArt = data
        isAlbumArtRemoved = false
    }
}
