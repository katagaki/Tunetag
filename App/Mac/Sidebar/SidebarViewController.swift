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

    var selectedNode: SidebarNode? {
        outlineView.item(atRow: outlineView.selectedRow) as? SidebarNode
    }

    func selectInitialNode() {
        guard outlineView.selectedRow < 0 else { return }
        outlineView.reloadData()
        outlineView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        Task {
            await rootNode.loadChildren()
            outlineView.reloadItem(rootNode, reloadChildren: true)
            outlineView.expandItem(rootNode)
        }
    }

    /// Folders show a disclosure triangle until they're listed, which happens
    /// as soon as their row appears, so the triangle settles before it's clicked.
    func loadChildren(of node: SidebarNode) {
        Task {
            await node.loadChildren()
            outlineView.reloadItem(node, reloadChildren: true)
        }
    }
}

extension NSUserInterfaceItemIdentifier {
    static let sidebarColumn = NSUserInterfaceItemIdentifier("SidebarColumn")
    static let sidebarCell = NSUserInterfaceItemIdentifier("SidebarCell")
}
