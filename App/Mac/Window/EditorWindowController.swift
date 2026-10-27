//
//  EditorWindowController.swift
//  Tunetag
//

import AppKit

final class EditorWindowController: NSWindowController, NSWindowDelegate {

    private(set) var session: EditorSession
    private(set) var splitViewController: EditorSplitViewController
    var onClose: (() -> Void)?
    /// Asks to open dropped files, in this window or in a new one.
    var onOpen: ((_ urls: [URL], _ inThisWindow: Bool) -> Void)?
    private var accessedURLs: [URL] = []

    init(session: EditorSession) {
        self.session = session
        // Bookmarked URLs only open up to the sandbox once asked to.
        accessedURLs = session.openedURLs.filter { $0.startAccessingSecurityScopedResource() }
        splitViewController = EditorSplitViewController(session: session)
        let window = EditorWindow(contentViewController: splitViewController)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.title = session.title
        window.toolbarStyle = .unified
        window.setContentSize(NSSize(width: 1180, height: 720))
        window.minSize = NSSize(width: 900, height: 480)
        window.setFrameAutosaveName("EditorWindow")
        super.init(window: window)
        window.delegate = self
        window.toolbar = makeToolbar()
        window.acceptDroppedFiles()
        window.onDrop = { [weak self] urls in
            self?.askWhereToOpen(urls)
        }
        observeDirtyState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Shows another session in this window, in place of the current one.
    func replace(with newSession: EditorSession) {
        guard let window else { return }
        accessedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        session = newSession
        accessedURLs = newSession.openedURLs.filter { $0.startAccessingSecurityScopedResource() }
        let frame = window.frame
        splitViewController = EditorSplitViewController(session: newSession)
        window.contentViewController = splitViewController
        window.setFrame(frame, display: true)
        window.title = newSession.title
        window.subtitle = ""
        window.isDocumentEdited = false
        observeDirtyState()
    }

    private func observeDirtyState() {
        splitViewController.onDirtyChange = { [weak window] isDirty in
            window?.isDocumentEdited = isDirty
        }
    }

    private func askWhereToOpen(_ urls: [URL]) {
        guard let window, window.attachedSheet == nil else { return }
        let alert = NSAlert()
        alert.messageText = urls.count == 1
            ? String(format: MacText.string("Drop.Title.One"), urls[0].lastPathComponent)
            : String(format: MacText.string("Drop.Title.Many"), urls.count)
        alert.informativeText = window.isDocumentEdited
            ? MacText.string("Drop.Message.Unsaved")
            : MacText.string("Drop.Message")
        alert.addButton(withTitle: MacText.string("Drop.NewWindow"))
        alert.addButton(withTitle: MacText.string("Drop.ThisWindow"))
        alert.addButton(withTitle: MacText.shared("Shared.Cancel"))
        alert.beginSheetModal(for: window) { [weak self] response in
            switch response {
            case .alertFirstButtonReturn: self?.onOpen?(urls, false)
            case .alertSecondButtonReturn: self?.onOpen?(urls, true)
            default: break
            }
        }
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
