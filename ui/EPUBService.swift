import Foundation
import ZIPFoundation
import UIKit

class EPUBService {
    static let shared = EPUBService()
    
    func extractCover(from epubURL: URL) -> UIImage? {
        
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            try fileManager.unzipItem(at: epubURL, to: tempDir)
            
            let enumerator = fileManager.enumerator(at: tempDir, includingPropertiesForKeys: nil)
            
            while let fileURL = enumerator?.nextObject() as? URL {
                let name = fileURL.lastPathComponent.lowercased()
                
                if name.contains("cover") && (name.hasSuffix(".jpg") || name.hasSuffix(".png")) {
                    if let data = try? Data(contentsOf: fileURL) {
                        return UIImage(data: data)
                    }
                }
            }
        } catch {
            print("EPUB Error:", error)
        }
        return nil
    }
}
