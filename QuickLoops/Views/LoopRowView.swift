import SwiftUI

struct LoopRowView: View {
    let loop: SavedLoop
    let isCurrentlyPreviewing: Bool
    let onLoad: () -> Void
    let onPreview: (Bool) -> Void
    let onDelete: () -> Void
    let onRename: () -> Void
    let onExport: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Loop icon
            Image(systemName: "waveform")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            // Loop info
            VStack(alignment: .leading, spacing: 4) {
                Text(loop.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(loop.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(loop.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(loop.relativeDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                if isHovered {
                    // Preview button (new)
                    Button(action: { onPreview(isCurrentlyPreviewing) }) {
                        Image(systemName: isCurrentlyPreviewing ? "pause.fill" : "play.fill")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(isCurrentlyPreviewing ? .orange : .blue)
                    .help(isCurrentlyPreviewing ? "Stop preview" : "Preview loop")
                    
                    // Secondary actions (shown on hover)
                    Button(action: onExport) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.borderless)
                    .help("Export loop")
                    
                    Button(action: onRename) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.borderless)
                    .help("Rename loop")
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                    .help("Delete loop")
                }
                
                // Primary load button
                Button(action: onLoad) {
                    Text("Load")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Load", action: onLoad)
            Button(isCurrentlyPreviewing ? "Stop Preview" : "Preview") {
                onPreview(isCurrentlyPreviewing)
            }
            Divider()
            Button("Rename", action: onRename)
            Button("Export", action: onExport)
            Divider()
            Button("Delete", action: onDelete)
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        LoopRowView(
            loop: SavedLoop(
                name: "Morning Jam",
                filename: "morning_jam_001.wav",
                createdDate: Date().addingTimeInterval(-86400 * 2), // 2 days ago
                duration: 32.5,
                fileSize: 1_800_000
            ),
            isCurrentlyPreviewing: false,
            onLoad: {},
            onPreview: { _ in },
            onDelete: {},
            onRename: {},
            onExport: {}
        )
        
        LoopRowView(
            loop: SavedLoop(
                name: "Bass Line Experiment",
                filename: "bass_line_002.wav",
                createdDate: Date().addingTimeInterval(-3600), // 1 hour ago
                duration: 75.2,
                fileSize: 3_200_000
            ),
            isCurrentlyPreviewing: true,
            onLoad: {},
            onPreview: { _ in },
            onDelete: {},
            onRename: {},
            onExport: {}
        )
    }
    .padding()
} 