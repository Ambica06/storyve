//
//  EPUBViewController.swift
//  storyveApp
//
//  Created by Ambica Bhatia on 11/05/26.
//

internal import UIKit
import ReadiumShared
import ReadiumNavigator

final class EPUBViewController: UIViewController {
    private let book: Book

    init(book: Book) {
        self.book = book
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

    private func openBook() {
        Task {
            do {
                let fileURL = EPUBService.shared.resolveBooksPath(book.epubPath)

                let publication = try await EPUBService.shared.openPublication(at: fileURL)

                let navigator = try EPUBNavigatorViewController(publication: publication, initialLocation: nil)

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
}
