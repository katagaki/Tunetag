//
//  SceneDelegate.swift
//  Tunetag
//

import SFBAudioEngine
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

        let browser = UIDocumentBrowserViewController(forOpening: [.audio])
        browser.allowsDocumentCreation = false
        browser.allowsPickingMultipleItems = true
        browser.shouldShowFileExtensions = true
        browser.delegate = self

        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: self,
            action: #selector(moreTapped)
        )
        browser.additionalLeadingNavigationBarButtonItems = [moreButton]

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

    private func presentTagEditor(files: [FSFile], accessedURLs: [URL],
                                   from presenter: UIViewController) {
        guard !files.isEmpty else {
            accessedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
            let alert = UIAlertController(
                title: String(localized: "Alert.NoMP3Files.Title"),
                message: String(localized: "Alert.NoMP3Files.Message"),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: String(localized: "Shared.OK"), style: .default))
            presenter.present(alert, animated: true)
            return
        }
        let hostingController = UIHostingController(
            rootView: TagEditorSheet(files: files, accessedURLs: accessedURLs)
        )
        hostingController.isModalInPresentation = true
        presenter.present(hostingController, animated: true)
    }
}

// MARK: - UIDocumentBrowserViewControllerDelegate

extension SceneDelegate: UIDocumentBrowserViewControllerDelegate {

    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         didPickDocumentsAt documentURLs: [URL]) {
        var accessedURLs: [URL] = []
        var files: [FSFile] = []

        for url in documentURLs {
            _ = url.startAccessingSecurityScopedResource()
            accessedURLs.append(url)
            if AudioFile.handlesPaths(withExtension: url.pathExtension.lowercased()) {
                files.append(FSFile(name: url.lastPathComponent,
                                    path: url.path(percentEncoded: false),
                                    isArbitrarilyLoadedFromDragAndDrop: true))
            }
        }

        presentTagEditor(files: files, accessedURLs: accessedURLs, from: controller)
    }
}
