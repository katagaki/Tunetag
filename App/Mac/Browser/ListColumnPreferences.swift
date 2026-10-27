//
//  ListColumnPreferences.swift
//  Tunetag
//

import Foundation
import Observation

extension Notification.Name {
    static let listColumnsDidChange = Notification.Name("ListColumnsDidChange")
}

/// Which List view columns show, and in what order, as chosen in Settings.
@MainActor @Observable
final class ListColumnPreferences {

    static let shared = ListColumnPreferences()

    private static let orderKey = "List.ColumnOrder"
    private static let hiddenKey = "List.HiddenColumns"

    private(set) var order: [ListColumn]
    private(set) var hidden: Set<ListColumn>

    private init() {
        let defaults = UserDefaults.standard
        let storedOrder = (defaults.stringArray(forKey: Self.orderKey) ?? []).compactMap(ListColumn.init)
        order = storedOrder + ListColumn.allCases.filter { !storedOrder.contains($0) }
        hidden = Set((defaults.stringArray(forKey: Self.hiddenKey) ?? []).compactMap(ListColumn.init))
    }

    var visibleColumns: [ListColumn] {
        order.filter { !hidden.contains($0) }
    }

    var isCustomized: Bool {
        order != ListColumn.allCases || !hidden.isEmpty
    }

    func isHidden(_ column: ListColumn) -> Bool {
        hidden.contains(column)
    }

    /// The last visible column can't be hidden, so the List view always has one.
    func setHidden(_ isHidden: Bool, for column: ListColumn) {
        if isHidden {
            guard visibleColumns.count > 1 else { return }
            hidden.insert(column)
        } else {
            hidden.remove(column)
        }
        save()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        order.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func reset() {
        order = ListColumn.allCases
        hidden = []
        save()
    }

    private func save() {
        UserDefaults.standard.set(order.map(\.rawValue), forKey: Self.orderKey)
        UserDefaults.standard.set(hidden.map(\.rawValue), forKey: Self.hiddenKey)
        NotificationCenter.default.post(name: .listColumnsDidChange, object: self)
    }
}
