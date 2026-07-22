//
//  EPUBReaderContainer.swift
//  storyveApp
//
//  Created by Ambica Bhatia on 11/05/26.
//

import SwiftUI

struct EPUBReaderContainer: UIViewControllerRepresentable {
    let book: Book
    
    func makeUIViewController(context: Context) -> EPUBViewController {
        return EPUBViewController(book: book)
    }
    
    func updateUIViewController(_ uiViewController: EPUBViewController, context: Context) {}
}
