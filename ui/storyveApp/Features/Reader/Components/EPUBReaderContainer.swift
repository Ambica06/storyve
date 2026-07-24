//
//  EPUBReaderContainer.swift
//  storyveApp
//
//  Created by Ambica Bhatia on 11/05/26.
//

import SwiftUI
import SwiftData
import ReadiumShared

struct EPUBReaderContainer: UIViewControllerRepresentable {
    let book: Book
    let pendingLink: ReadiumShared.Link?
    let onLinkHandled: () -> Void
    let pendingLocator: Locator?
    let onLocatorHandled: () -> Void
    let onPublicationLoaded: (Publication) -> Void

    @Environment(\.modelContext) private var modelContext

    func makeUIViewController(context: Context) -> EPUBViewController {
        let controller = EPUBViewController(book: book, modelContext: modelContext)
        controller.onPublicationLoaded = onPublicationLoaded
        return controller
    }

    func updateUIViewController(_ uiViewController: EPUBViewController, context: Context) {
        if let link = pendingLink {
            uiViewController.navigate(to: link)
            DispatchQueue.main.async {
                onLinkHandled()
            }
        }
        if let locator = pendingLocator {
            uiViewController.navigate(to: locator)
            DispatchQueue.main.async {
                onLocatorHandled()
            }
        }
    }
}
