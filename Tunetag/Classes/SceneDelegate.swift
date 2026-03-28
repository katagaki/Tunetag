//
//  SceneDelegate.swift
//  Tunetag
//

import StoreKit
import SwiftUI
import TipKit
import UIKit
import UniformTypeIdentifiers

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let navigationManager = NavigationManager()

    // MARK: - Scene lifecycle

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        configureTipKit()
        promptReviewIfNeeded(in: windowScene)

        let browser = UIDocumentBrowserViewController(forOpening: [.mp3])
        browser.allowsDocumentCreation = false
        browser.allowsPickingMultipleItems = true
        browser.shouldShowFileExtensions = true
        browser.delegate = self

        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(moreTapped)
        )
        browser.additionalTrailingNavigationBarButtonItems = [moreButton]

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = browser
        window?.makeKeyAndVisible()
    }

    // MARK: - Private helpers

    private func configureTipKit() {
        if #available(iOS 17.0, *) {
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        }
    }

    private func promptReviewIfNeeded(in windowScene: UIWindowScene) {
        let launchCount = UserDefaults.standard.integer(forKey: "LaunchCount") + 1
        UserDefaults.standard.set(launchCount, forKey: "LaunchCount")
        guard launchCount > 2,
              !UserDefaults.standard.bool(forKey: "ReviewPrompted") else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            SKStoreReviewController.requestReview(in: windowScene)
        }
        UserDefaults.standard.set(true, forKey: "ReviewPrompted")
    }

    @objc private func moreTapped() {
        guard let browser = window?.rootViewController else { return }
        let hostingController = UIHostingController(
            rootView: MoreView().environmentObject(navigationManager)
        )
        browser.present(hostingController, animated: true)
    }
}

// MARK: - UIDocumentBrowserViewControllerDelegate

extension SceneDelegate: UIDocumentBrowserViewControllerDelegate {

    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         didPickDocumentsAt documentURLs: [URL]) {
        let files = documentURLs.compactMap { url -> FSFile? in
            guard url.pathExtension.lowercased() == "mp3" else { return nil }
            _ = url.startAccessingSecurityScopedResource()
            return FSFile(name: url.lastPathComponent,
                          path: url.path(percentEncoded: false),
                          isArbitrarilyLoadedFromDragAndDrop: true)
        }
        guard !files.isEmpty else { return }
        let hostingController = UIHostingController(rootView: TagEditorSheet(files: files))
        hostingController.isModalInPresentation = true
        controller.present(hostingController, animated: true)
    }
}
