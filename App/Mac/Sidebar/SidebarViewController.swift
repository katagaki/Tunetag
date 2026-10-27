//
//  SidebarViewController.swift
//  Tunetag
//

import AppKit

final class SidebarViewController: NSViewController {

    let rootNode: SidebarNode
    let outlineView = NSOutlineView()
    var onSelect: ((SidebarNode) -> Void)?

    init(session: EditorSession) {
        switch session {
        case .folder(let url): rootNode = SidebarNode(kind: .folder(url), isRoot: true)
        case .files(let urls): rootNode = SidebarNode(kind: .files(urls), isRoot: true)
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        let column = NSTableColumn(identifier: .sidebarColumn)
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.headerView = nil
        outlineView.style = .sourceList
        outlineView.rowSizeStyle = .default
        outlineView.floatsGroupRows = false
        outlineView.autosaveExpandedItems = false
        outlineView.dataSource = self
        outlineView.delegate = self
        let scrollView = NSScrollView()
        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        view = scrollView
    }

    func selectInitialNode() {
        guard outlineView.selectedRow < 0 else { return }
        outlineView.reloadData()
        outlineView.expandItem(rootNode)
        outlineView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
    }
}

extension NSUserInterfaceItemIdentifier {
    static let sidebarColumn = NSUserInterfaceItemIdentifier("SidebarColumn")
    static let sidebarCell = NSUserInterfaceItemIdentifier("SidebarCell")
}
