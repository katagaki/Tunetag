//
//  EditorWindowController+Toolbar.swift
//  Tunetag
//

import AppKit

extension NSToolbarItem.Identifier {
    static let viewMode = NSToolbarItem.Identifier("ViewMode")
    static let extendedTags = NSToolbarItem.Identifier("ExtendedTags")
}

extension EditorWindowController: NSToolbarDelegate {

    func makeToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "EditorToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        return toolbar
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            .toggleSidebar,
            .sidebarTrackingSeparator,
            .flexibleSpace,
            .viewMode,
            .inspectorTrackingSeparator,
            .flexibleSpace,
            .extendedTags,
            .toggleInspector
        ]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
        case .viewMode: viewModeItem()
        case .extendedTags: extendedTagsItem()
        default: nil
        }
    }

    private func viewModeItem() -> NSToolbarItem {
        let labels = [MacText.string("ViewMode.Grid"), MacText.string("ViewMode.List")]
        let images = ["square.grid.2x2", "list.bullet"].enumerated().map { index, symbolName in
            NSImage(systemSymbolName: symbolName, accessibilityDescription: labels[index]) ?? NSImage()
        }
        let group = NSToolbarItemGroup(
            itemIdentifier: .viewMode,
            images: images,
            selectionMode: .selectOne,
            labels: labels,
            target: self,
            action: #selector(changeViewMode(_:))
        )
        group.label = MacText.string("Toolbar.ViewMode")
        group.selectedIndex = splitViewController.browserViewController.viewMode == .grid ? 0 : 1
        return group
    }

    /// A menu of inspector options, which shows or hides the extended tags.
    private func extendedTagsItem() -> NSToolbarItem {
        let label = MacText.shared("TagEditor.ExtendedTags")
        let toggleItem = MainMenuBuilder.item("Menu.ShowExtendedTags", action: #selector(toggleExtendedTags(_:)))
        toggleItem.target = self
        let menu = NSMenu()
        menu.addItem(toggleItem)
        let item = NSMenuToolbarItem(itemIdentifier: .extendedTags)
        item.image = NSImage(systemSymbolName: "tag", accessibilityDescription: label)
        item.label = label
        item.toolTip = label
        item.menu = menu
        return item
    }
}
