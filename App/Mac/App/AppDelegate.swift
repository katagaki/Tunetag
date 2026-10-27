//
//  AppDelegate.swift
//  Tunetag
//

import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowControllers: [EditorWindowController] = []
    private var settingsWindowController: SettingsWindowController?
    private var isOpenPanelShown = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        NSApp.mainMenu = MainMenuBuilder.build()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard windowControllers.isEmpty else { return }
        if Preferences.startsWithPreviousSelection, let session = EditorSession(urls: SessionStore.restore()) {
            open(session)
        } else {
            showOpenPanel()
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        open(urls)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag, windowControllers.isEmpty {
            showOpenPanel()
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    @objc func openDocument(_ sender: Any?) {
        showOpenPanel()
    }

    @objc func showSettings(_ sender: Any?) {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
            settingsWindowController?.window?.center()
        }
        settingsWindowController?.showWindow(nil)
    }

    private func showOpenPanel() {
        guard !isOpenPanelShown else { return }
        isOpenPanelShown = true
        OpenPanel.present { [weak self] urls in
            self?.isOpenPanelShown = false
            self?.open(urls)
        }
    }

    private func open(_ urls: [URL]) {
        guard let session = EditorSession(urls: urls) else { return }
        SessionStore.remember(urls)
        open(session)
    }

    private func open(_ session: EditorSession) {
        let controller = EditorWindowController(session: session)
        controller.onClose = { [weak self, weak controller] in
            self?.windowControllers.removeAll { $0 === controller }
        }
        windowControllers.append(controller)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }
}
