//
//  EditorSplitViewController.swift
//  Tunetag
//

import AppKit
import SwiftUI

final class EditorSplitViewController: NSSplitViewController {

    let session: EditorSession
    let sidebarViewController: SidebarViewController
    let browserViewController = BrowserViewController()
    let inspectorModel = TagInspectorModel()
    var onDirtyChange: ((Bool) -> Void)?
    var onDrop: (([URL]) -> Void)?
    private var includeSubfoldersObserver: NSObjectProtocol?

    init(session: EditorSession) {
        self.session = session
        sidebarViewController = SidebarViewController(session: session)
        super.init(nibName: nil, bundle: nil)
        let dropView = FileDropSplitView()
        dropView.onDrop = { [weak self] urls in
            self?.onDrop?(urls)
        }
        splitView = dropView
        if case .folder(let url) = session {
            browserViewController.rootFolder = url
        }
        sidebarViewController.onSelect = { [weak self] node in
            self?.browserViewController.show(node.kind)
            self?.view.window?.subtitle = node.isRoot ? "" : node.title
        }
        includeSubfoldersObserver = NotificationCenter.default.addObserver(
            forName: .includeSubfoldersDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let node = self.sidebarViewController.selectedNode else { return }
                self.browserViewController.show(node.kind, keepingSelection: true)
            }
        }
        browserViewController.onSelectionChange = { [weak self] files in
            self?.inspectorModel.select(files)
        }
        inspectorModel.onSave = { [weak self] files in
            self?.browserViewController.refreshTags(of: files)
        }
        inspectorModel.onDirtyChange = { [weak self] isDirty in
            self?.onDirtyChange?(isDirty)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        sidebarItem.minimumThickness = 180
        sidebarItem.maximumThickness = 360
        sidebarItem.canCollapse = true
        if case .files = session {
            sidebarItem.isCollapsed = true
        }
        let contentItem = NSSplitViewItem(viewController: browserViewController)
        contentItem.minimumThickness = 360
        let inspectorHost = NSHostingController(rootView: TagInspectorView(model: inspectorModel))
        inspectorHost.sizingOptions = []
        let inspectorItem = NSSplitViewItem(inspectorWithViewController: inspectorHost)
        inspectorItem.minimumThickness = 300
        inspectorItem.maximumThickness = 440
        inspectorItem.canCollapse = true
        addSplitViewItem(sidebarItem)
        addSplitViewItem(contentItem)
        addSplitViewItem(inspectorItem)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        sidebarViewController.selectInitialNode()
    }
}
