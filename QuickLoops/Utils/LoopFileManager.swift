import Foundation
import AVFoundation

enum LoopError: LocalizedError {
    case noAudioToSave
    case fileNotFound
    case duplicateName
    case saveFailure(String)
    case loadFailure(String)
    case libraryCorrupted
    case invalidAudioFile
    case insufficientDiskSpace
    
    var errorDescription: String? {
        switch self {
        case .noAudioToSave:
            return "No audio recorded to save"
        case .fileNotFound:
            return "Loop file not found"
        case .duplicateName:
            return "A loop with this name already exists"
        case .saveFailure(let details):
            return "Failed to save loop: \(details)"
        case .loadFailure(let details):
            return "Failed to load loop: \(details)"
        case .libraryCorrupted:
            return "Loop library is corrupted and needs to be rebuilt"
        case .invalidAudioFile:
            return "Invalid or corrupted audio file"
        case .insufficientDiskSpace:
            return "Insufficient disk space to save loop"
        }
    }
}

struct LoopFileManager {
    static let savedLoopsDirectory: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                   in: .userDomainMask).first!
        let loopsPath = documentsPath.appendingPathComponent("SavedLoops")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: loopsPath, 
                                               withIntermediateDirectories: true)
        return loopsPath
    }()
    
    static let libraryMetadataURL: URL = {
        return savedLoopsDirectory.appendingPathComponent("library.json")
    }()
    
    // MARK: - File Operations
    
    static func saveTemporaryLoopAs(name: String, from tempURL: URL) throws -> SavedLoop {
        // Validate source file exists
        guard FileManager.default.fileExists(atPath: tempURL.path) else {
            throw LoopError.fileNotFound
        }
        
        // Get metadata from source file
        let metadata = try getLoopMetadata(for: tempURL)
        
        // Generate unique filename
        let filename = generateUniqueFilename(for: name)
        let destinationURL = savedLoopsDirectory.appendingPathComponent(filename)
        
        // Copy file to saved loops directory
        try copyLoopFile(from: tempURL, to: destinationURL)
        
        // Create SavedLoop object
        let savedLoop = SavedLoop(
            name: name,
            filename: filename,
            createdDate: Date(),
            duration: metadata.duration,
            fileSize: metadata.fileSize
        )
        
        return savedLoop
    }
    
    static func copyLoopFile(from sourceURL: URL, to destinationURL: URL) throws {
        do {
            // Remove destination if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Copy file
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw LoopError.saveFailure(error.localizedDescription)
        }
    }
    
    static func deleteLoopFile(_ loop: SavedLoop) throws {
        let fileURL = loop.fileURL
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw LoopError.fileNotFound
        }
        
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            throw LoopError.saveFailure("Failed to delete file: \(error.localizedDescription)")
        }
    }
    
    static func generateUniqueFilename(for name: String) -> String {
        let sanitizedName = sanitizeFilename(name)
        let baseFilename = "\(sanitizedName).wav"
        
        var counter = 1
        var filename = baseFilename
        
        while FileManager.default.fileExists(atPath: savedLoopsDirectory.appendingPathComponent(filename).path) {
            filename = "\(sanitizedName)_\(counter).wav"
            counter += 1
        }
        
        return filename
    }
    
    private static func sanitizeFilename(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/<>:\"|?*\\")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(50) // Limit filename length
            .description
    }
    
    // MARK: - Metadata Operations
    
    static func getLoopMetadata(for fileURL: URL) throws -> (duration: TimeInterval, fileSize: Int64) {
        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Get duration using AVFoundation (synchronous for simplicity)
        let asset = AVAsset(url: fileURL)
        let duration: TimeInterval
        
        if #available(macOS 13.0, *) {
            // Use the new async API but wait synchronously for compatibility
            let semaphore = DispatchSemaphore(value: 0)
            var loadedDuration: CMTime = .zero
            var loadError: Error?
            
            Task {
                do {
                    loadedDuration = try await asset.load(.duration)
                } catch {
                    loadError = error
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            
            if loadError != nil {
                throw LoopError.invalidAudioFile
            }
            
            duration = CMTimeGetSeconds(loadedDuration)
        } else {
            // Fallback for older macOS versions
            duration = CMTimeGetSeconds(asset.duration)
        }
        
        guard duration.isFinite && duration > 0 else {
            throw LoopError.invalidAudioFile
        }
        
        return (duration: duration, fileSize: fileSize)
    }
    
    static func validateLoopFile(_ fileURL: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return false
        }
        
        // Basic audio file validation
        let asset = AVAsset(url: fileURL)
        let duration: TimeInterval
        
        if #available(macOS 13.0, *) {
            // Use the new async API but wait synchronously for compatibility
            let semaphore = DispatchSemaphore(value: 0)
            var loadedDuration: CMTime = .zero
            var hasError = false
            
            Task {
                do {
                    loadedDuration = try await asset.load(.duration)
                } catch _ {
                    hasError = true
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            
            if hasError {
                return false
            }
            
            duration = CMTimeGetSeconds(loadedDuration)
        } else {
            // Fallback for older macOS versions
            duration = CMTimeGetSeconds(asset.duration)
        }
        
        return duration.isFinite && duration > 0
    }
    
    // MARK: - Export Operations
    
    static func exportLoop(_ loop: SavedLoop, to destinationURL: URL) throws {
        guard validateLoopFile(loop.fileURL) else {
            throw LoopError.fileNotFound
        }
        
        try copyLoopFile(from: loop.fileURL, to: destinationURL)
    }
    
    // MARK: - Cleanup Operations
    
    static func cleanupOrphanedFiles() {
        // This method can be called to clean up any orphaned files
        // For now, we'll keep it simple and just log any issues
        do {
            let files = try FileManager.default.contentsOfDirectory(at: savedLoopsDirectory, 
                                                                   includingPropertiesForKeys: nil)
            print("Found \(files.count) files in saved loops directory")
        } catch {
            print("Failed to enumerate saved loops directory: \(error)")
        }
    }
    
    // MARK: - Disk Space Management
    
    static func getAvailableDiskSpace() -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: savedLoopsDirectory.path)
            return attributes[.systemFreeSize] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    static func checkDiskSpaceForFile(at url: URL) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        let availableSpace = getAvailableDiskSpace()
        
        // Require at least 10MB of free space after saving
        let requiredSpace = fileSize + (10 * 1024 * 1024)
        
        if availableSpace < requiredSpace {
            throw LoopError.insufficientDiskSpace
        }
    }
} 
