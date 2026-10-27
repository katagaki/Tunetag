//
//  EditorWindow.swift
//  Tunetag
//

import AppKit

/// Takes audio files and folders dropped anywhere on the window that doesn't
/// take drops itself, such as the inspector's album art.
final class EditorWindow: NSWindow {

    var onDrop: (([URL]) -> Void)?

    func acceptDroppedFiles() {
        registerForDraggedTypes([.fileURL])
    }

    @objc func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        droppableURLs(in: sender).isEmpty ? [] : .copy
    }

    @objc func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        droppableURLs(in: sender).isEmpty ? [] : .copy
    }

    @objc func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = droppableURLs(in: sender)
        guard !urls.isEmpty else { return false }
        // Asking where to open them waits until the drag has finished.
        DispatchQueue.main.async { [weak self] in
            self?.onDrop?(urls)
        }
        return true
    }

    private func droppableURLs(in info: NSDraggingInfo) -> [URL] {
        let urls = info.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] ?? []
        return urls.filter { $0.isDirectory || AudioFileLister.isSupportedAudioFile($0) }
    }
}
