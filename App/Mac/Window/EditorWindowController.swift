//
//  EditorWindowController.swift
//  Tunetag
//

import AppKit

final class EditorWindowController: NSWindowController, NSWindowDelegate {

    let session: EditorSession
    let splitViewController: EditorSplitViewController
    var onClose: (() -> Void)?
    private var accessedURLs: [URL] = []

    init(session: EditorSession) {
        self.session = session
        // Bookmarked URLs only open up to the sandbox once asked to.
        accessedURLs = session.openedURLs.filter { $0.startAccessingSecurityScopedResource() }
        splitViewController = EditorSplitViewController(session: session)
        let window = NSWindow(contentViewController: splitViewController)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.title = session.title
        window.toolbarStyle = .unified
        window.setContentSize(NSSize(width: 1180, height: 720))
        window.minSize = NSSize(width: 900, height: 480)
        window.setFrameAutosaveName("EditorWindow")
        super.init(window: window)
        window.delegate = self
        window.toolbar = makeToolbar()
        splitViewController.onDirtyChange = { [weak window] isDirty in
            window?.isDocumentEdited = isDirty
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func windowWillClose(_ notification: Notification) {
        accessedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        accessedURLs = []
        onClose?()
    }

    @objc func saveDocument(_ sender: Any?) {
        splitViewController.inspectorModel.save()
    }

    @objc func showAsGrid(_ sender: Any?) {
        setViewMode(.grid)
    }

    @objc func showAsList(_ sender: Any?) {
        setViewMode(.list)
    }

    @objc func toggleIncludeSubfolders(_ sender: Any?) {
        Preferences.includesSubfolders.toggle()
    }

    @objc func changeViewMode(_ sender: NSToolbarItemGroup) {
        setViewMode(sender.selectedIndex == 0 ? .grid : .list)
    }

    private func setViewMode(_ mode: BrowserViewMode) {
        splitViewController.browserViewController.viewMode = mode
        viewModeGroup?.selectedIndex = mode == .grid ? 0 : 1
    }

    var viewModeGroup: NSToolbarItemGroup? {
        window?.toolbar?.items.first { $0.itemIdentifier == .viewMode } as? NSToolbarItemGroup
    }
}

extension EditorWindowController: NSMenuItemValidation {

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let mode = splitViewController.browserViewController.viewMode
        switch menuItem.action {
        case #selector(saveDocument(_:)):
            return splitViewController.inspectorModel.canSave
        case #selector(showAsGrid(_:)):
            menuItem.state = mode == .grid ? .on : .off
        case #selector(showAsList(_:)):
            menuItem.state = mode == .list ? .on : .off
        case #selector(toggleIncludeSubfolders(_:)):
            menuItem.state = Preferences.includesSubfolders ? .on : .off
        default:
            break
        }
        return true
    }
}
