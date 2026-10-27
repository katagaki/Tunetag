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
    private let preparingView = NSStackView()
    private let preparingIndicator = NSProgressIndicator()
    private var columnsObserver: NSObjectProtocol?
    private var scanTask: Task<Void, Never>?
    private var preparingTask: Task<Void, Never>?

    /// Scans that finish sooner than this don't show the preparing indicator, so quick folders don't flicker.
    private static let preparingDelay: Duration = .seconds(1)

    /// The folder the window opened, which the Folder column shows paths relative to.
    var rootFolder: URL?
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
        configurePreparingView()
        for subview in [gridScrollView, listScrollView, emptyLabel, preparingView] {
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
            emptyLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            preparingView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            preparingView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        view = container
        tagCache.onUpdate = { [weak self] isComplete in
            self?.tagsDidLoad(isComplete: isComplete)
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

    /// Lists a sidebar node's files in the background. Showing another node
    /// cancels the scan, and a scan that runs long shows a preparing indicator.
    /// Reloading the same node keeps the files that are still there selected.
    func show(_ kind: SidebarNode.Kind, keepingSelection: Bool = false) {
        scanTask?.cancel()
        let includesSubfolders = Preferences.includesSubfolders
        let selectedFiles = keepingSelection ? selection.map { files[$0] } : []
        if !keepingSelection {
            showFiles([], selecting: [])
        }
        emptyLabel.isHidden = true
        showPreparingAfterDelay()
        scanTask = Task { [weak self] in
            let scan = Task.detached(priority: .userInitiated) {
                SidebarNode.fileURLs(of: kind, includingSubfolders: includesSubfolders)
            }
            let urls = await withTaskCancellationHandler {
                await scan.value
            } onCancel: {
                scan.cancel()
            }
            guard !Task.isCancelled, let self else { return }
            hidePreparing()
            showFiles(urls.map(AudioFileLister.file(for:)), selecting: selectedFiles)
        }
    }

    private func showFiles(_ newFiles: [FSFile], selecting selectedFiles: [FSFile]) {
        files = newFiles
        sortFiles()
        let selectedPaths = Set(selectedFiles.map(\.path))
        selection = IndexSet(files.indices.filter { selectedPaths.contains(files[$0].path) })
        collectionView.reloadData()
        tableView.reloadData()
        applySelection()
        emptyLabel.isHidden = !files.isEmpty
        tagCache.load(files)
        onSelectionChange?(selection.map { files[$0] })
    }

    private func configurePreparingView() {
        preparingIndicator.style = .spinning
        preparingIndicator.controlSize = .small
        let label = NSTextField(labelWithString: MacText.string("Browser.Preparing"))
        label.textColor = .secondaryLabelColor
        preparingView.orientation = .horizontal
        preparingView.spacing = 8
        preparingView.addArrangedSubview(preparingIndicator)
        preparingView.addArrangedSubview(label)
        preparingView.isHidden = true
    }

    private func showPreparingAfterDelay() {
        preparingTask?.cancel()
        preparingTask = Task { [weak self] in
            try? await Task.sleep(for: Self.preparingDelay)
            guard !Task.isCancelled, let self else { return }
            preparingView.isHidden = false
            preparingIndicator.startAnimation(nil)
        }
    }

    private func hidePreparing() {
        preparingTask?.cancel()
        preparingIndicator.stopAnimation(nil)
        preparingView.isHidden = true
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
