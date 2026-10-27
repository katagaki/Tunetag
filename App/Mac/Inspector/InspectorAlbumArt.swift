//
//  InspectorAlbumArt.swift
//  Tunetag
//

import SwiftUI
import UniformTypeIdentifiers

struct InspectorAlbumArt: View {

    @Binding var albumArt: Data?
    @Binding var isAlbumArtRemoved: Bool
    @State private var isImporting = false

    private var albumArtImage: NSImage? {
        albumArt.flatMap(NSImage.init(data:))
    }

    var body: some View {
        VStack(spacing: 10) {
            Group {
                if let albumArtImage {
                    Image(nsImage: albumArtImage)
                        .resizable()
                } else {
                    Image(.albumGeneric)
                        .resizable()
                }
            }
            .scaledToFill()
            .frame(width: 180, height: 180)
            .clipShape(.rect(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.primary, lineWidth: 1 / 3)
                    .opacity(0.3)
            }
            .dropDestination(for: URL.self) { urls, _ in
                guard let url = urls.first else { return false }
                return setAlbumArt(from: url)
            }
            HStack {
                Button(MacText.string("Inspector.ChooseAlbumArt")) {
                    isImporting = true
                }
                if albumArt != nil {
                    Button(MacText.string("Inspector.RemoveAlbumArt"), role: .destructive) {
                        albumArt = nil
                        isAlbumArtRemoved = true
                    }
                    .help(MacText.shared("TagEditor.RemoveAlbumArt"))
                }
            }
            .controlSize(.small)
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.image]) { result in
            if case .success(let url) = result {
                _ = setAlbumArt(from: url)
            }
        }
    }

    private func setAlbumArt(from url: URL) -> Bool {
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing { url.stopAccessingSecurityScopedResource() }
        }
        guard let data = try? Data(contentsOf: url), NSImage(data: data) != nil else { return false }
        albumArt = data
        isAlbumArtRemoved = false
        return true
    }
}
