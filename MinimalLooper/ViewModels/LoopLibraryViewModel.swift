import Foundation
import SwiftUI
import Combine

class LoopLibraryViewModel: ObservableObject {
    @Published var loopLibrary = LoopLibrary()
    @Published var showingDeleteConfirmation = false
    @Published var showingRenameDialog = false
    @Published var selectedLoop: SavedLoop?
    @Published var newLoopName = ""
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .dateDescending
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var previewEngine = LoopPreviewEngine()
    
    private var cancellables = Set<AnyCancellable>()
    
    enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First" 
        case nameAscending = "Name A-Z"
        case nameDescending = "Name Z-A"
        case durationAscending = "Shortest First"
        case durationDescending = "Longest First"
    }
    
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe library errors
        loopLibrary.$lastError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.showError(error.localizedDescription)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var filteredAndSortedLoops: [SavedLoop] {
        var loops = loopLibrary.savedLoops
        
        // Apply search filter
        if !searchText.isEmpty {
            loops = loops.filter { loop in
                loop.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sorting
        switch sortOrder {
        case .dateDescending:
            loops.sort { $0.createdDate > $1.createdDate }
        case .dateAscending:
            loops.sort { $0.createdDate < $1.createdDate }
        case .nameAscending:
            loops.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .nameDescending:
            loops.sort { $0.name.localizedCompare($1.name) == .orderedDescending }
        case .durationAscending:
            loops.sort { $0.duration < $1.duration }
        case .durationDescending:
            loops.sort { $0.duration > $1.duration }
        }
        
        return loops
    }
    
    var isEmpty: Bool {
        return loopLibrary.isEmpty
    }
    
    var isLoading: Bool {
        return loopLibrary.isLoading
    }
    
    var libraryStats: String {
        let count = loopLibrary.totalLoops
        let size = loopLibrary.formattedTotalSize
        return "\(count) loop\(count == 1 ? "" : "s") • \(size)"
    }
    
    // MARK: - Actions
    
    func selectLoop(_ loop: SavedLoop) {
        selectedLoop = loop
    }
    
    func deleteLoop(_ loop: SavedLoop) {
        selectedLoop = loop
        showingDeleteConfirmation = true
    }
    
    func confirmDelete() {
        guard let loop = selectedLoop else { return }
        
        do {
            try loopLibrary.deleteLoop(loop)
            selectedLoop = nil
            showingDeleteConfirmation = false
        } catch {
            showError("Failed to delete loop: \(error.localizedDescription)")
        }
    }
    
    func renameLoop(_ loop: SavedLoop) {
        selectedLoop = loop
        newLoopName = loop.name
        showingRenameDialog = true
    }
    
    func confirmRename() {
        guard let loop = selectedLoop else { return }
        
        let trimmedName = newLoopName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            showError("Loop name cannot be empty")
            return
        }
        
        do {
            try loopLibrary.renameLoop(loop, to: trimmedName)
            selectedLoop = nil
            newLoopName = ""
            showingRenameDialog = false
        } catch {
            showError("Failed to rename loop: \(error.localizedDescription)")
        }
    }
    
    func refreshLibrary() {
        loopLibrary.refreshLibrary()
    }
    
    func exportLoop(_ loop: SavedLoop) {
        // This will be handled by the view showing a file save dialog
        selectedLoop = loop
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Preview Functionality
    
    func previewLoop(_ loop: SavedLoop) {
        do {
            try previewEngine.previewLoop(loop)
        } catch {
            showError("Failed to preview loop: \(error.localizedDescription)")
        }
    }
    
    func stopPreview() {
        previewEngine.stopPreview()
    }
    
    func isLoopPreviewing(_ loop: SavedLoop) -> Bool {
        return previewEngine.isPreviewingLoop(loop)
    }
    
    func setPreviewVolume(_ volume: Float) {
        previewEngine.setPreviewVolume(volume)
    }
    
    // MARK: - Error Handling
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    func clearError() {
        showingError = false
        errorMessage = ""
    }
    
    // MARK: - Utility Functions
    
    func formatFileSize(_ bytes: Int64) -> String {
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        return AudioUtils.formatDuration(duration)
    }
} 