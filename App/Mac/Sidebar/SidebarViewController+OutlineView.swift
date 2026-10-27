//
//  SidebarViewController+OutlineView.swift
//  Tunetag
//

import AppKit

extension SidebarViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? SidebarNode else { return 1 }
        return node.children?.count ?? 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let node = item as? SidebarNode else { return rootNode }
        return (node.children ?? [])[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? SidebarNode else { return false }
        return node.children.map { !$0.isEmpty } ?? true
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? SidebarNode else { return nil }
        let cell = outlineView.makeView(withIdentifier: .sidebarCell, owner: self) as? SidebarCellView
            ?? SidebarCellView()
        cell.identifier = .sidebarCell
        cell.textField?.stringValue = node.title
        cell.imageView?.image = NSImage(systemSymbolName: node.symbolName, accessibilityDescription: nil)
        if node.children == nil {
            loadChildren(of: node)
        }
        return cell
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let node = selectedNode else { return }
        onSelect?(node)
    }
}
