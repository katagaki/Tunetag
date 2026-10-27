//
//  MainMenuBuilder.swift
//  Tunetag
//

import AppKit

enum MainMenuBuilder {

    static func build() -> NSMenu {
        let mainMenu = NSMenu()
        let windowMenu = windowMenu()
        for submenu in [applicationMenu(), fileMenu(), editMenu(), viewMenu(), windowMenu] {
            let item = NSMenuItem()
            item.submenu = submenu
            mainMenu.addItem(item)
        }
        NSApp.windowsMenu = windowMenu
        return mainMenu
    }

    static var applicationName: String {
        Bundle.main.localizedInfoDictionary?["CFBundleName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
            ?? ProcessInfo.processInfo.processName
    }

    static func item(
        _ key: String,
        action: Selector?,
        keyEquivalent: String = "",
        modifiers: NSEvent.ModifierFlags = .command
    ) -> NSMenuItem {
        let item = NSMenuItem(title: MacText.string(key), action: action, keyEquivalent: keyEquivalent)
        item.keyEquivalentModifierMask = modifiers
        return item
    }

    static func formattedItem(_ key: String, action: Selector?, keyEquivalent: String = "") -> NSMenuItem {
        let title = String(format: MacText.string(key), applicationName)
        return NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
    }
}
