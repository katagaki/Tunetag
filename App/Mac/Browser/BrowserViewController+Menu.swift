//
//  BrowserViewController+Menu.swift
//  Tunetag
//

import AppKit

extension BrowserViewController: NSMenuDelegate {

    func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        let item = NSMenuItem(
            title: MacText.string("Browser.ShowInFinder"),
            action: #selector(showInFinder(_:)),
            keyEquivalent: ""
        )
        item.target = self
        menu.addItem(item)
        return menu
    }

    /// Right-clicking outside the selection acts on the clicked file alone, as Finder does.
    @objc func showInFinder(_ sender: Any?) {
        let clickedIndex = viewMode == .list ? tableView.clickedRow : clickedGridIndex()
        let isOutsideSelection = clickedIndex >= 0 && !selection.contains(clickedIndex)
        let indexes = isOutsideSelection ? IndexSet(integer: clickedIndex) : selection
        let urls = indexes.map { URL(filePath: files[$0].path) }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let clickedIndex = viewMode == .list ? tableView.clickedRow : clickedGridIndex()
        let hasTarget = clickedIndex >= 0 || !selection.isEmpty
        menu.items.forEach { $0.isEnabled = hasTarget }
    }

    private func clickedGridIndex() -> Int {
        guard let event = NSApp.currentEvent else { return -1 }
        let point = collectionView.convert(event.locationInWindow, from: nil)
        return collectionView.indexPathForItem(at: point)?.item ?? -1
    }
}
