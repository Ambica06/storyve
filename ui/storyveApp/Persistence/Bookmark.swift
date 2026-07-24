//
//  Bookmark.swift
//  storyveApp
//

import Foundation
import SwiftData

@Model
final class Bookmark {
    var id: UUID
    var bookId: UUID
    var locatorJSON: String
    var title: String?
    var createdAt: Date

    init(bookId: UUID, locatorJSON: String, title: String? = nil) {
        self.id = UUID()
        self.bookId = bookId
        self.locatorJSON = locatorJSON
        self.title = title
        self.createdAt = Date()
    }
}
