//
//  OpenPanel.swift
//  Tunetag
//

import AppKit
import UniformTypeIdentifiers

enum OpenPanel {

    @MainActor
    static func present(completion: @escaping ([URL]) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.folder] + AudioFileLister.supportedExtensions.compactMap {
            UTType(filenameExtension: $0)
        }
        panel.message = MacText.string("OpenPanel.Message")
        panel.prompt = MacText.string("OpenPanel.Prompt")
        panel.begin { response in
            completion(response == .OK ? panel.urls : [])
        }
    }
}
