//
//  ReaderView.swift
//  storyveApp
//
//  Created by Ambica Bhatia on 11/05/26.
//

import SwiftUI
import SwiftData
import ReadiumShared

struct ReaderView: View {
    let book: Book

    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [Bookmark]

    @State private var publication: Publication?
    @State private var pendingLink: ReadiumShared.Link?
    @State private var pendingLocator: Locator?
    @State private var showingContents = false

    init(book: Book) {
        self.book = book
        let bookId = book.id
        _bookmarks = Query(filter: #Predicate<Bookmark> { $0.bookId == bookId })
    }

    private var currentBookmark: Bookmark? {
        guard let locatorJSON = book.locatorJSON else { return nil }
        return bookmarks.first { $0.locatorJSON == locatorJSON }
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            EPUBReaderContainer(
                book: book,
                pendingLink: pendingLink,
                onLinkHandled: { pendingLink = nil },
                pendingLocator: pendingLocator,
                onLocatorHandled: { pendingLocator = nil },
                onPublicationLoaded: { publication = $0 }
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if publication != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingContents = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        toggleBookmark()
                    } label: {
                        Image(systemName: currentBookmark != nil ? "bookmark.fill" : "bookmark")
                    }
                    .disabled(book.locatorJSON == nil)
                }
            }
        }
        .sheet(isPresented: $showingContents) {
            if let publication {
                ContentsView(book: book, publication: publication) { link in
                    pendingLink = link
                    showingContents = false
                } onSelectLocator: { locator in
                    pendingLocator = locator
                    showingContents = false
                }
            }
        }
    }

    private func toggleBookmark() {
        guard let locatorJSON = book.locatorJSON else { return }
        if let existing = currentBookmark {
            modelContext.delete(existing)
        } else {
            let title = (try? Locator(jsonString: locatorJSON))?.title
            modelContext.insert(Bookmark(bookId: book.id, locatorJSON: locatorJSON, title: title))
        }
        try? modelContext.save()
    }
}
