//
//  DocumentBrowserView.swift
//  Tunetag
//

import StoreKit
import SwiftUI
import TipKit
import UIKit
import UniformTypeIdentifiers

// MARK: - Container view (handles TipKit + review prompt)

struct DocumentBrowserContainerView: View {

    @Environment(\.requestReview) var requestReview
    @AppStorage(wrappedValue: false, "ReviewPrompted", store: .standard) var hasReviewBeenPrompted: Bool
    @AppStorage(wrappedValue: 0, "LaunchCount", store: .standard) var launchCount: Int

    var onFilesOpened: ([URL]) -> Void
    var onMoreTapped: () -> Void

    var body: some View {
        DocumentBrowserView(onFilesOpened: onFilesOpened, onMoreTapped: onMoreTapped)
            .task {
                if #available(iOS 17.0, *) {
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                        .datastoreLocation(.applicationDefault)
                    ])
                }
                launchCount += 1
                if launchCount > 2 && !hasReviewBeenPrompted {
                    requestReview()
                    hasReviewBeenPrompted = true
                }
            }
    }
}

// MARK: - UIDocumentBrowserViewController wrapper

struct DocumentBrowserView: UIViewControllerRepresentable {

    var onFilesOpened: ([URL]) -> Void
    var onMoreTapped: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentBrowserViewController {
        let browser = UIDocumentBrowserViewController(forOpening: [.mp3])
        browser.allowsDocumentCreation = false
        browser.allowsPickingMultipleItems = true
        browser.shouldShowFileExtensions = true
        browser.delegate = context.coordinator

        let moreButton = UIBarButtonItem(
            title: NSLocalizedString("TabTitle.More", comment: ""),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.moreTapped)
        )
        browser.additionalTrailingNavigationBarButtonItems = [moreButton]

        return browser
    }

    func updateUIViewController(_ uiViewController: UIDocumentBrowserViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentBrowserViewControllerDelegate {

        var parent: DocumentBrowserView

        init(_ parent: DocumentBrowserView) {
            self.parent = parent
        }

        func documentBrowser(_ controller: UIDocumentBrowserViewController,
                             didPickDocumentsAt documentURLs: [URL]) {
            parent.onFilesOpened(documentURLs)
        }

        @objc func moreTapped() {
            parent.onMoreTapped()
        }
    }
}
