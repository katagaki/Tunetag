//
//  TunetagApp.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import SwiftUI

@main
struct TunetagApp: App {

    // Window and root view controller are managed by SceneDelegate.
    // UIDocumentBrowserViewController must be the root view controller of the
    // window to enable all features including multiple selection.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // SceneDelegate sets up the UIWindow directly; this WindowGroup is not rendered.
        WindowGroup { EmptyView() }
    }
}
