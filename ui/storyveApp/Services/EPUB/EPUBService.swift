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
    
    // MARK: - Books Directory
    
    private var booksDirectory: URL {
        let documents = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        let booksDirectory = documents.appendingPathComponent("Books")
        
        if !FileManager.default.fileExists(atPath: booksDirectory.path) {
            try? FileManager.default.createDirectory(
                at: booksDirectory,
                withIntermediateDirectories: true
            )
        }
        
        return booksDirectory
    }
    
    // MARK: - Import EPUB
    
    func importEPUB(from url: URL) async throws -> EPUBMetadata {
        
        // MARK: - Copy to Books Directory
        
        let bookFolder = booksDirectory.appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(
            at: bookFolder,
            withIntermediateDirectories: true
        )
        
        let destinationURL = bookFolder.appendingPathComponent(url.lastPathComponent)
        
        try FileManager.default.copyItem(at: url, to: destinationURL)
        
        // MARK: - Open Publication
        
        guard let absoluteURL = destinationURL.anyURL.absoluteURL else {
            throw NSError(domain: "EPUBImport", code: -1)
        }
        
        let asset = try await retriever.retrieve(url: absoluteURL).get()
        
        let publication = try await publicationOpener.open(
            asset: asset,
            allowUserInteraction: false
        ).get()
        
        // MARK: - Extract Metadata
        
        let title = publication.metadata.title
            ?? destinationURL.deletingPathExtension().lastPathComponent
        
        let author = publication.metadata.authors.first?.name
            ?? "Unknown Author"
        
        // MARK: - Extract Cover

        var coverPath: String?

        let coverResult = await publication.cover()

        if case .success(let image) = coverResult, let image = image {
            let coverData = image.pngData() ?? Data()
            let coverURL = bookFolder.appendingPathComponent("cover.jpg")
            try coverData.write(to: coverURL)
            coverPath = coverURL.path
        }
        
        return EPUBMetadata(
            title: title,
            author: author,
            coverPath: coverPath,
            epubPath: destinationURL.path
        )
    }
}
