//
//  MainMenuBuilder+File.swift
//  Tunetag
//

import AppKit

extension MainMenuBuilder {

    static func fileMenu() -> NSMenu {
        let menu = NSMenu(title: MacText.string("Menu.File"))
        menu.addItem(item("Menu.Open", action: #selector(AppDelegate.openDocument(_:)), keyEquivalent: "o"))
        menu.addItem(.separator())
        menu.addItem(item("Menu.Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        menu.addItem(item(
            "Menu.Save",
            action: #selector(EditorWindowController.saveDocument(_:)),
            keyEquivalent: "s"
        ))
        return menu
    }
}
