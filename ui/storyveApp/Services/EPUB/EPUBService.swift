import Foundation
import ReadiumShared
import ReadiumStreamer
internal import UIKit

final class EPUBService {
    
    static let shared = EPUBService()
    
    private let httpClient = DefaultHTTPClient()
    private lazy var retriever: AssetRetriever = AssetRetriever(httpClient: httpClient)
    private lazy var publicationOpener: PublicationOpener = PublicationOpener(
        parser: DefaultPublicationParser(
            httpClient: httpClient,
            assetRetriever: retriever,
            pdfFactory: DefaultPDFDocumentFactory()
        )
    )
    
    private init() {}

    // MARK: - Open Publication

    /// Opens a Readium `Publication` from a local file URL. Shared by import
    /// (metadata/cover extraction) and reading (navigator rendering) so both
    /// use the same asset retrieval / parsing pipeline.
    func openPublication(at url: URL) async throws -> Publication {

        guard let absoluteURL = url.anyURL.absoluteURL else {
            throw NSError(domain: "EPUBImport", code: -1)
        }

        let asset = try await retriever.retrieve(url: absoluteURL).get()

        return try await publicationOpener.open(
            asset: asset,
            allowUserInteraction: false
        ).get()
    }

    // MARK: - Books Directory

    /// Resolves a path stored on `Book` (relative to the Books directory) to an
    /// absolute file URL under the *current* app container. Paths must not be
    /// stored as absolute — the container UUID changes across reinstalls/updates.
    func resolveBooksPath(_ relativePath: String) -> URL {
        booksDirectory.appendingPathComponent(relativePath)
    }

    private var booksDirectory: URL {
        
        do {
            
            let appSupport = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            let booksDirectory = appSupport.appendingPathComponent(
                "Books",
                isDirectory: true
            )
            
            if !FileManager.default.fileExists(atPath: booksDirectory.path) {
                
                try FileManager.default.createDirectory(
                    at: booksDirectory,
                    withIntermediateDirectories: true
                )
            }
            
            return booksDirectory
            
        } catch {
            fatalError("Failed to create books directory: \(error)")
        }
    }
    
    // MARK: - Import EPUB
    
    func importEPUB(from url: URL) async throws -> EPUBMetadata {
        
        // MARK: - Copy to Books Directory
        
        let bookFolderName = UUID().uuidString
        let bookFolder = booksDirectory.appendingPathComponent(bookFolderName)

        try FileManager.default.createDirectory(
            at: bookFolder,
            withIntermediateDirectories: true
        )

        let destinationURL = bookFolder.appendingPathComponent(url.lastPathComponent)

        try FileManager.default.copyItem(at: url, to: destinationURL)

        let publication = try await openPublication(at: destinationURL)

        // MARK: - Extract Metadata
        
        let title = publication.metadata.title
            ?? destinationURL.deletingPathExtension().lastPathComponent
        
        let author = publication.metadata.authors.first?.name
            ?? "Unknown Author"
        
        // MARK: - Extract Cover

        var coverPath: String?

        let coverResult = await publication.cover()

        if case .success(let image) = coverResult, let image = image {
            let coverData = image.jpegData(compressionQuality: 0.8) ?? Data()
            let coverURL = bookFolder.appending(
                path: "cover.jpg",
                directoryHint: .notDirectory
            )
            try coverData.write(to: coverURL)
            coverPath = "\(bookFolderName)/\(coverURL.lastPathComponent)"
        }

        return EPUBMetadata(
            title: title,
            author: author,
            coverPath: coverPath,
            epubPath: "\(bookFolderName)/\(destinationURL.lastPathComponent)"
        )
    }
}
