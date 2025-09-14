import Foundation
import AVFoundation

struct SavedLoop: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let filename: String
    let createdDate: Date
    let duration: TimeInterval
    let fileSize: Int64
    
    init(name: String, filename: String, createdDate: Date, duration: TimeInterval, fileSize: Int64) {
        self.id = UUID()
        self.name = name
        self.filename = filename
        self.createdDate = createdDate
        self.duration = duration
        self.fileSize = fileSize
    }
    
    // Computed properties
    var fileURL: URL {
        LoopFileManager.savedLoopsDirectory.appendingPathComponent(filename)
    }
    
    var formattedDuration: String {
        AudioUtils.formatDuration(duration)
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: createdDate)
    }
    
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdDate, relativeTo: Date())
    }
} 