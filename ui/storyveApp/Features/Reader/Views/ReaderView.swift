//
//  ReaderView.swift
//  storyveApp
//
//  Created by Ambica Bhatia on 11/05/26.
//

import SwiftUI

struct ReaderView: View {
    let book: Book
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            EPUBReaderContainer(book: book)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
