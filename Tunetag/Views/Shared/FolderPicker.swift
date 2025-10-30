//
//  FolderPicker.swift
//  Tunetag
//
//  Created by GitHub Copilot on 2023/10/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct FolderPicker: UIViewControllerRepresentable {

    @Binding var isPresented: Bool
    var onFolderSelected: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder, .mp3], asCopy: false)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FolderPicker

        init(_ parent: FolderPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onFolderSelected(urls)
            parent.isPresented = false
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
        }
    }
}
