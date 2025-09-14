import Foundation
import Combine

class LoopLibrary: ObservableObject {
    @Published var savedLoops: [SavedLoop] = []
    @Published var isLoading = false
    @Published var lastError: LoopError?
    
    private let metadataURL: URL
    
    init() {
        metadataURL = LoopFileManager.libraryMetadataURL
        loadLibrary()
    }
    
    // MARK: - Public Interface
    
    func saveLoop(_ loop: SavedLoop) {
        // Add to array
        savedLoops.append(loop)
        
        // Sort by creation date (newest first)
        savedLoops.sort { $0.createdDate > $1.createdDate }
        
        // Persist to disk
        saveLibrary()
    }
    
    func deleteLoop(_ loop: SavedLoop) throws {
        // Delete file first
        try LoopFileManager.deleteLoopFile(loop)
        
        // Remove from array
        savedLoops.removeAll { $0.id == loop.id }
        
        // Persist changes
        saveLibrary()
    }
    
    func renameLoop(_ loop: SavedLoop, to newName: String) throws {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LoopError.saveFailure("Loop name cannot be empty")
        }
        
        // Check for duplicate names
        if savedLoops.contains(where: { $0.name == newName && $0.id != loop.id }) {
            throw LoopError.duplicateName
        }
        
        // Find the loop in our array
        guard let index = savedLoops.firstIndex(where: { $0.id == loop.id }) else {
            throw LoopError.fileNotFound
        }
        
        // Create updated loop with new name
        let updatedLoop = SavedLoop(
            name: newName,
            filename: savedLoops[index].filename,
            createdDate: savedLoops[index].createdDate,
            duration: savedLoops[index].duration,
            fileSize: savedLoops[index].fileSize
        )
        
        // Replace in array
        savedLoops[index] = updatedLoop
        
        // Persist changes
        saveLibrary()
    }
    
    func refreshLibrary() {
        loadLibrary()
    }
    
    // MARK: - Computed Properties
    
    var isEmpty: Bool {
        return savedLoops.isEmpty
    }
    
    var totalLoops: Int {
        return savedLoops.count
    }
    
    var totalSize: Int64 {
        return savedLoops.reduce(0) { $0 + $1.fileSize }
    }
    
    var formattedTotalSize: String {
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    // MARK: - Private Implementation
    
    private func loadLibrary() {
        isLoading = true
        lastError = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                var loops: [SavedLoop] = []
                
                if FileManager.default.fileExists(atPath: self?.metadataURL.path ?? "") {
                    let data = try Data(contentsOf: self?.metadataURL ?? URL(fileURLWithPath: ""))
                    loops = try JSONDecoder().decode([SavedLoop].self, from: data)
                    
                    // Validate that files still exist and remove orphaned entries
                    loops = loops.filter { loop in
                        let fileExists = LoopFileManager.validateLoopFile(loop.fileURL)
                        if !fileExists {
                            print("Removing orphaned loop: \(loop.name)")
                        }
                        return fileExists
                    }
                    
                    // Sort by creation date (newest first)
                    loops.sort { $0.createdDate > $1.createdDate }
                }
                
                DispatchQueue.main.async {
                    self?.savedLoops = loops
                    self?.isLoading = false
                    
                    // If we removed orphaned entries, save the cleaned library
                    if loops.count != (try? JSONDecoder().decode([SavedLoop].self, from: Data(contentsOf: self?.metadataURL ?? URL(fileURLWithPath: ""))))?.count {
                        self?.saveLibrary()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.lastError = .libraryCorrupted
                    print("Failed to load loop library: \(error)")
                    
                    // Try to rebuild from existing files
                    self?.rebuildLibraryFromFiles()
                }
            }
        }
    }
    
    private func saveLibrary() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let data = try JSONEncoder().encode(self.savedLoops)
                try data.write(to: self.metadataURL)
            } catch {
                DispatchQueue.main.async {
                    self.lastError = .saveFailure("Failed to save library metadata: \(error.localizedDescription)")
                }
                print("Failed to save loop library: \(error)")
            }
        }
    }
    
    private func rebuildLibraryFromFiles() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let files = try FileManager.default.contentsOfDirectory(
                    at: LoopFileManager.savedLoopsDirectory,
                    includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]
                ).filter { $0.pathExtension.lowercased() == "wav" }
                
                var rebuiltLoops: [SavedLoop] = []
                
                for fileURL in files {
                    do {
                        let metadata = try LoopFileManager.getLoopMetadata(for: fileURL)
                        let filename = fileURL.lastPathComponent
                        let name = String(filename.dropLast(4)) // Remove .wav extension
                        
                        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                        let creationDate = attributes[.creationDate] as? Date ?? Date()
                        
                        let loop = SavedLoop(
                            name: name,
                            filename: filename,
                            createdDate: creationDate,
                            duration: metadata.duration,
                            fileSize: metadata.fileSize
                        )
                        
                        rebuiltLoops.append(loop)
                    } catch {
                        print("Failed to process file \(fileURL.lastPathComponent): \(error)")
                    }
                }
                
                rebuiltLoops.sort { $0.createdDate > $1.createdDate }
                
                DispatchQueue.main.async {
                    self?.savedLoops = rebuiltLoops
                    self?.lastError = nil
                    self?.saveLibrary()
                    print("Successfully rebuilt library with \(rebuiltLoops.count) loops")
                }
            } catch {
                DispatchQueue.main.async {
                    self?.lastError = .libraryCorrupted
                }
                print("Failed to rebuild library from files: \(error)")
            }
        }
    }
} 