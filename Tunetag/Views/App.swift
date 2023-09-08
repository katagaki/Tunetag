//
//  TunetagApp.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import SwiftUI

@main
struct TunetagApp: App {

    @StateObject var tabManager = TabManager()
    @StateObject var navigationManager = NavigationManager()
    @StateObject var fileManager = FilesystemManager()
    @StateObject var batchFileManager = BatchFileManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(tabManager)
                .environmentObject(navigationManager)
                .environmentObject(fileManager)
                .environmentObject(batchFileManager)
        }
    }
}
