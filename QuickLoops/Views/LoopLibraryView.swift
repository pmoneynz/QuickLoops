import SwiftUI

struct LoopLibraryView: View {
    @StateObject private var viewModel = LoopLibraryViewModel()
    @Binding var isPresented: Bool
    let onLoadLoop: (SavedLoop) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            if viewModel.isLoading {
                loadingView
            } else if viewModel.isEmpty {
                emptyStateView
            } else {
                libraryContentView
            }
        }
        .frame(width: 500, height: 600)
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $viewModel.showingRenameDialog) {
            renameDialogView
        }
        .alert("Delete Loop", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.confirmDelete()
            }
        } message: {
            if let loop = viewModel.selectedLoop {
                Text("Are you sure you want to delete '\(loop.name)'? This action cannot be undone.")
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Title and close button
            HStack {
                Text("Loop Library")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Done") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
            }
            
            // Search and sort controls
            HStack(spacing: 12) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search loops...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: viewModel.clearSearch) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Sort picker
                Picker("Sort", selection: $viewModel.sortOrder) {
                    ForEach(LoopLibraryViewModel.SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
            }
            
            // Library stats
            if !viewModel.isEmpty {
                HStack {
                    Text(viewModel.libraryStats)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Preview volume control
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.1")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: Binding(
                            get: { viewModel.previewEngine.previewVolume },
                            set: { viewModel.setPreviewVolume($0) }
                        ), in: 0...1)
                        .frame(width: 60)
                        
                        Text("Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Refresh") {
                        viewModel.refreshLibrary()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.primary.opacity(0.1)),
            alignment: .bottom
        )
    }
    
    // MARK: - Content Views
    
    private var libraryContentView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredAndSortedLoops) { loop in
                    LoopRowView(
                        loop: loop,
                        isCurrentlyPreviewing: viewModel.isLoopPreviewing(loop),
                        onLoad: { loadLoop(loop) },
                        onPreview: { isPlaying in 
                            if isPlaying {
                                viewModel.stopPreview()
                            } else {
                                viewModel.previewLoop(loop)
                            }
                        },
                        onDelete: { viewModel.deleteLoop(loop) },
                        onRename: { viewModel.renameLoop(loop) },
                        onExport: { exportLoop(loop) }
                    )
                    
                    if loop.id != viewModel.filteredAndSortedLoops.last?.id {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Saved Loops")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Record and save your first loop to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading loops...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var renameDialogView: some View {
        VStack(spacing: 20) {
            Text("Rename Loop")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("New Name:")
                    .font(.headline)
                
                TextField("Enter new name", text: $viewModel.newLoopName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if !viewModel.newLoopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            viewModel.confirmRename()
                        }
                    }
            }
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    viewModel.showingRenameDialog = false
                    viewModel.newLoopName = ""
                }
                .keyboardShortcut(.escape)
                
                Button("Rename") {
                    viewModel.confirmRename()
                }
                .disabled(viewModel.newLoopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 300)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Actions
    
    private func loadLoop(_ loop: SavedLoop) {
        onLoadLoop(loop)
        isPresented = false
    }
    
    private func exportLoop(_ loop: SavedLoop) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = loop.name
        savePanel.allowedContentTypes = [.audio]
        savePanel.canCreateDirectories = true
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try LoopFileManager.exportLoop(loop, to: url)
                } catch {
                    viewModel.errorMessage = "Failed to export loop: \(error.localizedDescription)"
                    viewModel.showingError = true
                }
            }
        }
    }
}

#Preview {
    LoopLibraryView(
        isPresented: .constant(true),
        onLoadLoop: { _ in }
    )
} 