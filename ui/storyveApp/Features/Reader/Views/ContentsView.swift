//
//  ContentsView.swift
//  storyveApp
//

import SwiftUI
import SwiftData
import ReadiumShared

struct ContentsView: View {
    let book: Book
    let publication: Publication
    let onSelectLink: (ReadiumShared.Link) -> Void
    let onSelectLocator: (Locator) -> Void

    private enum Section: String, CaseIterable {
        case contents = "Contents"
        case bookmarks = "Bookmarks"
    }

    @Environment(\.dismiss) private var dismiss
    @Query private var bookmarks: [Bookmark]

    @State private var section: Section = .contents
    @State private var tocEntries: [(level: Int, link: ReadiumShared.Link)] = []

    init(book: Book, publication: Publication, onSelectLink: @escaping (ReadiumShared.Link) -> Void, onSelectLocator: @escaping (Locator) -> Void) {
        self.book = book
        self.publication = publication
        self.onSelectLink = onSelectLink
        self.onSelectLocator = onSelectLocator
        let bookId = book.id
        _bookmarks = Query(
            filter: #Predicate<Bookmark> { $0.bookId == bookId },
            sort: \Bookmark.createdAt,
            order: .reverse
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $section) {
                    ForEach(Section.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch section {
                case .contents:
                    List(Array(tocEntries.enumerated()), id: \.offset) { _, entry in
                        Button {
                            onSelectLink(entry.link)
                        } label: {
                            Text(entry.link.title ?? entry.link.href)
                                .padding(.leading, CGFloat(entry.level) * 16)
                        }
                    }
                case .bookmarks:
                    if bookmarks.isEmpty {
                        Spacer()
                        Text("No bookmarks yet")
                            .foregroundStyle(.secondary)
                        Spacer()
                    } else {
                        List(bookmarks) { bookmark in
                            Button {
                                if let locator = try? Locator(jsonString: bookmark.locatorJSON) {
                                    onSelectLocator(locator)
                                }
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(bookmark.title ?? "Bookmark")
                                    Text(bookmark.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(section.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                if let toc = try? await publication.tableOfContents().get() {
                    tocEntries = flatten(toc)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func flatten(_ links: [ReadiumShared.Link], level: Int = 0) -> [(level: Int, link: ReadiumShared.Link)] {
        links.flatMap { [(level, $0)] + flatten($0.children, level: level + 1) }
    }
}
