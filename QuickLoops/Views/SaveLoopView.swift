import SwiftUI

struct SaveLoopView: View {
    @Binding var isPresented: Bool
    @State private var loopName: String = ""
    @State private var isSaving: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    
    let currentFileURL: URL?
    let onSave: (String) throws -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Save Loop")
                .font(.title2)
                .fontWeight(.bold)
            
            // Loop name input
            VStack(alignment: .leading, spacing: 8) {
                Text("Loop Name:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Enter loop name", text: $loopName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if canSave {
                            saveLoop()
                        }
                    }
            }
            
            // Metadata display
            if let fileURL = currentFileURL {
                MetadataDisplayView(fileURL: fileURL)
            }
            
            // Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("Save") {
                    saveLoop()
                }
                .disabled(!canSave)
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .disabled(isSaving)
        .onAppear {
            // Generate default name based on timestamp
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd, HH:mm"
            loopName = "Loop \(formatter.string(from: Date()))"
            
            // Focus the text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // This will work in a real app context
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
            }
        } message: {
            Text(errorMessage)
        }
        .overlay(
            Group {
                if isSaving {
                    ProgressView("Saving...")
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.9))
                        .cornerRadius(8)
                }
            }
        )
    }
    
    private var canSave: Bool {
        return !loopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }
    
    private func saveLoop() {
        let trimmedName = loopName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            showError("Please enter a loop name")
            return
        }
        
        isSaving = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try onSave(trimmedName)
                DispatchQueue.main.async {
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isSaving = false
                    showError(error.localizedDescription)
                }
            }
        }
    }
    
    private func dismiss() {
        isPresented = false
        loopName = ""
        isSaving = false
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

struct MetadataDisplayView: View {
    let fileURL: URL
    @State private var duration: TimeInterval = 0
    @State private var fileSize: Int64 = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Duration:", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(AudioUtils.formatDuration(duration))
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Label("Size:", systemImage: "doc")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            loadMetadata()
        }
    }
    
    private func loadMetadata() {
        DispatchQueue.global(qos: .utility).async {
            do {
                let metadata = try LoopFileManager.getLoopMetadata(for: fileURL)
                DispatchQueue.main.async {
                    duration = metadata.duration
                    fileSize = metadata.fileSize
                }
            } catch {
                print("Failed to load metadata: \(error)")
            }
        }
    }
}

#Preview {
    SaveLoopView(
        isPresented: .constant(true),
        currentFileURL: URL(fileURLWithPath: "/tmp/test.wav"),
        onSave: { _ in }
    )
} 