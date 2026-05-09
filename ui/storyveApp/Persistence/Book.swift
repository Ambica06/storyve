//
//  Book.swift
//  storyveApp
//
//  Created by Ambica Bhatia on 09/05/26.
//

import Foundation
import SwiftData

@Model
final class Book {
    
    var id: UUID
    
    var title: String
    var author: String
    
    var epubPath: String
    var coverPath: String?
    
    var progress: Double
    var createdAt: Date
    
    init(
        title: String,
        author: String,
        epubPath:String,
        coverPath: String? = nil,
        progress: Double = 0
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.epubPath = epubPath
        self.coverPath = coverPath
        self.progress = progress
        self.createdAt = Date()
    }
}
