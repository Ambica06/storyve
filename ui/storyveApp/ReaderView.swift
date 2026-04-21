import SwiftUI

struct ReaderView: View {
    let book: Book
    
    var body: some View {
        ScrollView {
            Text("Reading \(book.title)...")
                .padding()
        }
        .navigationTitle(book.title)
    }
}
