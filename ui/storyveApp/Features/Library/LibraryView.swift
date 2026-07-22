import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct LibraryView: View {
    
    @Environment(\.modelContext)
    private var modelContext
    
    @Query(sort: \Book.createdAt, order: .reverse)
    private var books: [Book]
    
    @State private var showingImporter = false
    @State private var importErrorMessage: String?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                Color.black
                    .ignoresSafeArea()
                
                if books.isEmpty {
                    
                    emptyState
                    
                } else {
                    
                    ScrollView {
                        
                        LazyVGrid(
                            columns: columns,
                            spacing: 28
                        ) {
                            
                            ForEach(books) { book in
                                NavigationLink {
                                    ReaderView(book: book)
                                } label: {
                                    BookCard(book: book)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                importButton
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.epub]
            ) { result in

                handleImport(result)
            }
            .alert(
                "Couldn't Import Book",
                isPresented: Binding(
                    get: { importErrorMessage != nil },
                    set: { isPresented in
                        if !isPresented { importErrorMessage = nil }
                    }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importErrorMessage ?? "")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        
        VStack(spacing: 18) {
            
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.7))
            
            Text("Your library is empty")
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Text("Import your first EPUB to begin.")
                .foregroundStyle(.gray)
        }
    }
    
    // MARK: - Import Button
    
    private var importButton: some View {
        
        VStack {
            
            Spacer()
            
            HStack {
                
                Spacer()
                
                Button {
                    showingImporter = true
                } label: {
                    
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundStyle(.black)
                        .frame(width: 62, height: 62)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Handle Import
    
    private func handleImport(
        _ result: Result<URL, Error>
    ) {
        
        Task {
            
            do {
                
                let selectedFile = try result.get()
                
                let didAccess =
                    selectedFile.startAccessingSecurityScopedResource()
                
                defer {
                    if didAccess {
                        selectedFile.stopAccessingSecurityScopedResource()
                    }
                }
                
                let metadata =
                    try await EPUBService.shared.importEPUB(
                        from: selectedFile
                    )
                
                let book = Book(
                    title: metadata.title,
                    author: metadata.author,
                    epubPath: metadata.epubPath,
                    coverPath: metadata.coverPath
                )
                
                modelContext.insert(book)
                
                try modelContext.save()
                
            } catch {
                print("Import failed:", error)
                importErrorMessage = "This file may not be a valid EPUB. Please try a different book."
            }
        }
    }
}
