//
//  FilePreview.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/09.
//

import ID3TagEditor
import SwiftUI

struct FilePreview: View {

    let id3TagEditor = ID3TagEditor()
    @State var file: FSFile
    @State var tagData = Tag()

    var body: some View {
        List {
            FileHeaderSection(filename: file.name, albumArt: $tagData.albumArt, selectedAlbumArt: .constant(nil),
                              showsPhotosPicker: false)
            if file.filetype == .mp3 {
                TagDataSection(tagData: $tagData)
            }
        }
        .task {
            if file.filetype == .mp3 {
                await readAllTagData()
            }
        }
    }

    func readAllTagData() async {
        debugPrint("Attempting to read tag data for \(file.name) files...")
        do {
            let tag = try id3TagEditor.read(from: file.path)
            if let tag = tag {
                let tagContentReader = ID3TagContentReader(id3Tag: tag)
                tagData = await Tag(from: TagTyped(file, reader: tagContentReader))
            }
        } catch {
            debugPrint("Error occurred while reading tags: \n\(error.localizedDescription)")
        }
    }
}
