//
//  MainMenuBuilder+Window.swift
//  Tunetag
//

import AppKit

extension MainMenuBuilder {

    static func windowMenu() -> NSMenu {
        let menu = NSMenu(title: MacText.string("Menu.Window"))
        menu.addItem(item("Menu.Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"))
        menu.addItem(item("Menu.Zoom", action: #selector(NSWindow.performZoom(_:))))
        menu.addItem(.separator())
        menu.addItem(item("Menu.BringAllToFront", action: #selector(NSApplication.arrangeInFront(_:))))
        return menu
    }
}
