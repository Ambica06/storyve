import SwiftUI

struct BookCard: View {
    
    let book: Book
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            coverView
            
            VStack(alignment: .leading, spacing: 6) {
                
                Text(book.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }
            
            ProgressView(value: book.progress)
                .tint(.white.opacity(0.8))
        }
    }
    
    // MARK: - Cover View
    
    @ViewBuilder
    private var coverView: some View {
        
        if let coverPath = book.coverPath,
           let uiImage = UIImage(contentsOfFile: EPUBService.shared.resolveBooksPath(coverPath).path) {
            
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 160, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: .white.opacity(0.08), radius: 10)
            
        } else {
            
            ZStack {
                
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.35),
                                Color.black.opacity(0.9)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                VStack(spacing: 12) {
                    
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text(book.title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                }
            }
            .frame(width: 160, height: 240)
        }
    }
}
