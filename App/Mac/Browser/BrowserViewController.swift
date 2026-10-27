//
//  BrowserViewController.swift
//  Tunetag
//

import AppKit

final class BrowserViewController: NSViewController {

    let collectionView = NSCollectionView()
    let tableView = NSTableView()
    let tagCache = TagSummaryCache()
    private let gridScrollView = NSScrollView()
    private let listScrollView = NSScrollView()
    private let emptyLabel = NSTextField(labelWithString: MacText.string("Browser.Empty"))
    private var columnsObserver: NSObjectProtocol?

    var files: [FSFile] = []
    private(set) var selection = IndexSet()
    var isApplyingSelection = false
    var onSelectionChange: (([FSFile]) -> Void)?

    var viewMode: BrowserViewMode = BrowserViewMode(
        rawValue: UserDefaults.standard.string(forKey: Preferences.browserViewModeKey) ?? ""
    ) ?? .grid {
        didSet {
            UserDefaults.standard.set(viewMode.rawValue, forKey: Preferences.browserViewModeKey)
            updateVisibleView()
        }
    }

    override func loadView() {
        let container = NSView()
        configureGrid()
        configureList()
        gridScrollView.documentView = collectionView
        listScrollView.documentView = tableView
        listScrollView.hasHorizontalScroller = true
        emptyLabel.font = .preferredFont(forTextStyle: .title3)
        emptyLabel.textColor = .secondaryLabelColor
        for subview in [gridScrollView, listScrollView, emptyLabel] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(subview)
        }
        for scrollView in [gridScrollView, listScrollView] {
            scrollView.hasVerticalScroller = true
            scrollView.autohidesScrollers = true
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: container.topAnchor),
                scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
            ])
        }
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        view = container
        tagCache.onUpdate = { [weak self] in
            self?.reloadListValues()
        }
        columnsObserver = NotificationCenter.default.addObserver(
            forName: .listColumnsDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.rebuildColumns()
            }
        }
        updateVisibleView()
    }

    func show(_ urls: [URL]) {
        files = urls.map(AudioFileLister.file(for:))
        sortFiles()
        selection = []
        collectionView.reloadData()
        tableView.reloadData()
        emptyLabel.isHidden = !files.isEmpty
        tagCache.load(files)
        onSelectionChange?([])
    }

    func refreshTags(of savedFiles: [FSFile]) {
        tagCache.invalidate(savedFiles, reloading: files)
    }

    /// Records a selection made in either view and mirrors it into the other,
    /// so switching views keeps what's selected.
    func updateSelection(_ newSelection: IndexSet) {
        guard !isApplyingSelection, newSelection != selection else { return }
        selection = newSelection
        applySelection()
        onSelectionChange?(selection.map { files[$0] })
    }

    /// Moves the selection to where the same files now sit, without reloading the inspector.
    func replaceSelection(_ newSelection: IndexSet) {
        selection = newSelection
        applySelection()
    }

    func applySelection() {
        isApplyingSelection = true
        defer { isApplyingSelection = false }
        let indexPaths = Set(selection.map { IndexPath(item: $0, section: 0) })
        if collectionView.selectionIndexPaths != indexPaths {
            collectionView.selectionIndexPaths = indexPaths
        }
        if tableView.selectedRowIndexes != selection {
            tableView.selectRowIndexes(selection, byExtendingSelection: false)
        }
    }

    private func updateVisibleView() {
        gridScrollView.isHidden = viewMode != .grid
        listScrollView.isHidden = viewMode != .list
        let visibleView: NSView = viewMode == .grid ? collectionView : tableView
        if let window = view.window, window.firstResponder === collectionView || window.firstResponder === tableView {
            window.makeFirstResponder(visibleView)
        }
    }
}
