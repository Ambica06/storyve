//
//  EPUBViewController.swift
//  storyveApp
//
//  Created by Ambica Bhatia on 11/05/26.
//

internal import UIKit
import SwiftData
import ReadiumShared
import ReadiumNavigator

final class EPUBViewController: UIViewController {
    private let book: Book
    private let modelContext: ModelContext
    private var navigator: EPUBNavigatorViewController?

    private(set) var publication: Publication?
    var onPublicationLoaded: ((Publication) -> Void)?

    init(book: Book, modelContext: ModelContext) {
        self.book = book
        self.modelContext = modelContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        openBook()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let locator = navigator?.currentLocation {
            persist(locator)
        }
    }

    private func openBook() {
        Task {
            do {
                let fileURL = EPUBService.shared.resolveBooksPath(book.epubPath)

                let publication = try await EPUBService.shared.openPublication(at: fileURL)

                self.publication = publication
                onPublicationLoaded?(publication)

                let initialLocation = try book.locatorJSON.flatMap { try Locator(jsonString: $0) }

                let navigator = try EPUBNavigatorViewController(publication: publication, initialLocation: initialLocation)
                navigator.delegate = self
                self.navigator = navigator

                addChild(navigator)

                navigator.view.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(navigator.view)

                NSLayoutConstraint.activate([
                    navigator.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    navigator.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    navigator.view.topAnchor.constraint(equalTo: view.topAnchor),
                    navigator.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])

                navigator.didMove(toParent: self)
            } catch {
                print("Failed to open EPUB:", error)
            }
        }
    }

    func navigate(to link: Link) {
        Task { [weak self] in
            await self?.navigator?.go(to: link, options: NavigatorGoOptions(animated: false))
        }
    }

    func navigate(to locator: Locator) {
        Task { [weak self] in
            await self?.navigator?.go(to: locator, options: NavigatorGoOptions(animated: false))
        }
    }

    private func persist(_ locator: Locator) {
        book.locatorJSON = locator.jsonString
        book.progress = locator.locations.totalProgression ?? book.progress
        try? modelContext.save()
    }
}

extension EPUBViewController: EPUBNavigatorDelegate {
    func navigator(_ navigator: Navigator, locationDidChange locator: Locator) {
        persist(locator)
    }

    func navigator(_ navigator: Navigator, presentError error: NavigatorError) {
        print("Navigator error:", error)
    }
}
