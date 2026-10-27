//
//  FileDropSplitView.swift
//  Tunetag
//

import AppKit

/// The editor's split view. It takes audio files and folders dropped anywhere
/// in the window that doesn't take drops itself, such as the inspector's album art.
final class FileDropSplitView: NSSplitView {

    var onDrop: (([URL]) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isVertical = true
        dividerStyle = .thin
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        droppableURLs(in: sender).isEmpty ? [] : .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        droppableURLs(in: sender).isEmpty ? [] : .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = droppableURLs(in: sender)
        guard !urls.isEmpty else { return false }
        // Asking where to open them waits until the drag has finished.
        DispatchQueue.main.async { [weak self] in
            self?.onDrop?(urls)
        }
        return true
    }

    /// The sandbox only lets the app look at dragged files once they're dropped,
    /// so this goes by the URLs alone: folders end in a slash, and audio files by their extension.
    private func droppableURLs(in info: NSDraggingInfo) -> [URL] {
        let urls = info.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] ?? []
        return urls.filter { url in
            url.hasDirectoryPath || AudioFileLister.supportedExtensions.contains(url.pathExtension.lowercased())
        }
    }
}
