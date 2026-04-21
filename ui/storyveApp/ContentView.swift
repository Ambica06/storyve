import SwiftUI

struct Book: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    var coverImage: UIImage?
    let fileURL: URL
}

struct ContentView: View {
    
    @State private var books: [Book] = [
        Book(
            title: "1984",
            author: "George Orwell",
            coverImage: UIImage(named: "book1"),
            fileURL: URL(fileURLWithPath: "")
        ),
        Book(
            title: "The Alchemist",
            author: "Paulo Coelho",
            coverImage: UIImage(named: "book2"),
            fileURL: URL(fileURLWithPath: "")
        ),
        Book(
            title: "Atomic Habits",
            author: "James Clear",
            coverImage: UIImage(named: "book3"),
            fileURL: URL(fileURLWithPath: "")
        )
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                // 📚 Bookshelf Grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(books) { book in
                        NavigationLink(destination: ReaderView(book: book)) {
                            VStack {
                                
                                // Cover
                                VStack {
                                    if let image = book.coverImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                    }
                                }
                                .frame(width: 100, height: 150)
                                .cornerRadius(8)
                                .shadow(radius: 3)
                                
                                // Title
                                Text(book.title)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding()
                
                // 🔥 Recent Reads
                VStack(alignment: .leading) {
                    Text("Recent Reads")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(books.prefix(3)) { book in
                                VStack {
                                    
                                    VStack {
                                        if let image = book.coverImage {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                        }
                                    }
                                    .frame(width: 100, height: 150)
                                    .cornerRadius(8)
                                    .shadow(radius: 3)
                                    
                                    Text(book.title)
                                        .font(.caption)
                                }
                                .padding(.leading, 8)
                            }
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("My Books")
        }
        .onAppear {
            // Load test EPUB only once
            if books.count == 3,
               let url = Bundle.main.url(forResource: "sample", withExtension: "epub") {
                
                let cover = EPUBService.shared.extractCover(from: url)
                
                let newBook = Book(
                    title: "Test EPUB",
                    author: "Unknown",
                    coverImage: cover,
                    fileURL: url
                )
                
                books.append(newBook)
            }
        }
    }
}
