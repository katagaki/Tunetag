//
//  SettingsWindowController.swift
//  Tunetag
//

import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {

    init() {
        let tabs = SettingsTabViewController()
        tabs.tabStyle = .toolbar
        tabs.canPropagateSelectedChildViewControllerTitle = true
        tabs.transitionOptions = [.allowUserInteraction]
        let panes = [
            SettingsTab(MacText.string("Settings.General"), "gearshape") { GeneralSettingsPane() },
            SettingsTab(MacText.string("Settings.View"), "list.bullet.rectangle") { ViewSettingsPane() },
            SettingsTab(MacText.shared("More.Attributions"), "doc.text") { AttributionsSettingsPane() }
        ]
        for pane in panes {
            let hostingController = NSHostingController(rootView: pane.content)
            hostingController.sizingOptions = .intrinsicContentSize
            hostingController.title = pane.title
            let item = NSTabViewItem(viewController: hostingController)
            item.label = pane.title
            item.image = NSImage(systemSymbolName: pane.symbolName, accessibilityDescription: pane.title)
            tabs.addTabViewItem(item)
        }
        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable]
        window.toolbarStyle = .preference
        if let first = tabs.tabViewItems.first?.viewController {
            tabs.resize(window, toFit: first, animated: false)
        }
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

private struct SettingsTab {
    let title: String
    let symbolName: String
    let content: AnyView

    init<Content: View>(_ title: String, _ symbolName: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.symbolName = symbolName
        self.content = AnyView(content())
    }
}
