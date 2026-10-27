//
//  MainMenuBuilder+View.swift
//  Tunetag
//

import AppKit

extension MainMenuBuilder {

    static func viewMenu() -> NSMenu {
        let menu = NSMenu(title: MacText.string("Menu.View"))
        menu.addItem(item(
            "ViewMode.Grid",
            action: #selector(EditorWindowController.showAsGrid(_:)),
            keyEquivalent: "1"
        ))
        menu.addItem(item(
            "ViewMode.List",
            action: #selector(EditorWindowController.showAsList(_:)),
            keyEquivalent: "2"
        ))
        menu.addItem(.separator())
        menu.addItem(item(
            "Menu.IncludeSubfolders",
            action: #selector(EditorWindowController.toggleIncludeSubfolders(_:))
        ))
        menu.addItem(.separator())
        menu.addItem(item(
            "Menu.ShowSidebar",
            action: #selector(NSSplitViewController.toggleSidebar(_:)),
            keyEquivalent: "s",
            modifiers: [.command, .control]
        ))
        menu.addItem(item(
            "Menu.ShowInspector",
            action: #selector(NSSplitViewController.toggleInspector(_:)),
            keyEquivalent: "i",
            modifiers: [.command, .option]
        ))
        menu.addItem(.separator())
        menu.addItem(item(
            "Menu.EnterFullScreen",
            action: #selector(NSWindow.toggleFullScreen(_:)),
            keyEquivalent: "f",
            modifiers: [.command, .control]
        ))
        return menu
    }
}
