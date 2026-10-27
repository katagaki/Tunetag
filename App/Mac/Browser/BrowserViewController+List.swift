//
//  BrowserViewController+List.swift
//  Tunetag
//

import AppKit

extension BrowserViewController: NSTableViewDataSource, NSTableViewDelegate {

    func configureList() {
        tableView.style = .fullWidth
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = true
        tableView.allowsColumnReordering = false
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        tableView.dataSource = self
        tableView.delegate = self
        tableView.menu = makeContextMenu()
        rebuildColumns()
    }

    func rebuildColumns() {
        for column in tableView.tableColumns {
            tableView.removeTableColumn(column)
        }
        for listColumn in ListColumnPreferences.shared.visibleColumns {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(listColumn.rawValue))
            column.title = listColumn.title
            column.width = listColumn.defaultWidth
            column.minWidth = 44
            column.sortDescriptorPrototype = NSSortDescriptor(key: listColumn.rawValue, ascending: true)
            if listColumn.isNumeric {
                column.headerCell.alignment = .right
            }
            tableView.addTableColumn(column)
        }
        tableView.sortDescriptors = tableView.sortDescriptors.filter { descriptor in
            tableView.tableColumns.contains { $0.identifier.rawValue == descriptor.key }
        }
    }

    func reloadListValues() {
        guard tableView.numberOfRows > 0 else { return }
        tableView.reloadData(
            forRowIndexes: IndexSet(integersIn: 0..<tableView.numberOfRows),
            columnIndexes: IndexSet(integersIn: 0..<tableView.numberOfColumns)
        )
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        files.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn, let listColumn = ListColumn(rawValue: tableColumn.identifier.rawValue) else {
            return nil
        }
        let cell = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? NSTableCellView
            ?? makeCell(identifier: tableColumn.identifier)
        cell.textField?.stringValue = value(for: listColumn, of: files[row])
        cell.textField?.alignment = listColumn.isNumeric ? .right : .natural
        cell.textField?.lineBreakMode = listColumn == .folder ? .byTruncatingMiddle : .byTruncatingTail
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateSelection(tableView.selectedRowIndexes)
    }

    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        resortKeepingSelection()
    }

    /// Tag values arrive in chunks. A list sorted by a tag column is sorted again once they've all arrived.
    func tagsDidLoad(isComplete: Bool) {
        if isComplete, let column = sortColumn, column != .fileName, column != .folder {
            resortKeepingSelection()
        } else {
            reloadListValues()
        }
    }

    func value(for column: ListColumn, of file: FSFile) -> String {
        switch column {
        case .fileName: file.name
        case .folder: folderPath(of: file)
        default: tagCache.value(for: column, of: file)
        }
    }

    /// Sorts by the clicked column. Sorting by folder orders by folder, then file name,
    /// and ties in other columns fall back to that order too.
    func sortFiles() {
        guard let descriptor = tableView.sortDescriptors.first, let column = sortColumn else { return }
        let keys = files.map { file in
            (file, column == .folder ? "" : value(for: column, of: file), (file.path as NSString).pathComponents)
        }
        files = keys.sorted { lhs, rhs in
            var order = lhs.1.localizedStandardCompare(rhs.1)
            if order == .orderedSame {
                order = AudioFileLister.pathOrder(lhs.2, rhs.2)
            }
            return descriptor.ascending ? order == .orderedAscending : order == .orderedDescending
        }.map(\.0)
    }

    private var sortColumn: ListColumn? {
        tableView.sortDescriptors.first?.key.flatMap(ListColumn.init)
    }

    private func resortKeepingSelection() {
        let selectedFiles = selection.map { files[$0] }
        sortFiles()
        tableView.reloadData()
        collectionView.reloadData()
        replaceSelection(IndexSet(selectedFiles.compactMap { files.firstIndex(of: $0) }))
    }

    /// The file's folder, starting from the opened folder's name, or the full path for files opened on their own.
    private func folderPath(of file: FSFile) -> String {
        let folder = URL(filePath: file.path).deletingLastPathComponent()
        guard let rootFolder else { return folder.path(percentEncoded: false) }
        let rootComponents = rootFolder.pathComponents
        let folderComponents = folder.pathComponents
        guard folderComponents.starts(with: rootComponents) else { return folder.path(percentEncoded: false) }
        return folderComponents.dropFirst(rootComponents.count - 1).joined(separator: "/")
    }

    private func makeCell(identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = identifier
        let label = NSTextField(labelWithString: "")
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(label)
        cell.textField = label
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
            label.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }
}
