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
        cell.textField?.stringValue = tagCache.value(for: listColumn, of: files[row])
        cell.textField?.alignment = listColumn.isNumeric ? .right : .natural
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateSelection(tableView.selectedRowIndexes)
    }

    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        let selectedFiles = selection.map { files[$0] }
        sortFiles()
        tableView.reloadData()
        collectionView.reloadData()
        replaceSelection(IndexSet(selectedFiles.compactMap { files.firstIndex(of: $0) }))
    }

    func sortFiles() {
        guard let descriptor = tableView.sortDescriptors.first,
              let key = descriptor.key,
              let column = ListColumn(rawValue: key) else { return }
        files.sort { lhs, rhs in
            let order = tagCache.value(for: column, of: lhs)
                .localizedStandardCompare(tagCache.value(for: column, of: rhs))
            return descriptor.ascending ? order == .orderedAscending : order == .orderedDescending
        }
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
