import Foundation
import AVFoundation

struct AudioUtils {
    static let targetSampleRate: Double = 44100.0
    static let targetChannels: UInt32 = 2
    static let targetBitDepth: UInt32 = 16
    
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    static func getLooperRecordingsDirectory() -> URL {
        let documentsDirectory = getDocumentsDirectory()
        let looperDirectory = documentsDirectory.appendingPathComponent("LooperFiles")
        
        // Create the directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: looperDirectory, 
                                                   withIntermediateDirectories: true, 
                                                   attributes: nil)
        } catch {
            print("Failed to create LooperFiles directory: \(error)")
            // Fallback to Documents directory if creation fails
            return documentsDirectory
        }
        
        return looperDirectory
    }
    
    static func createLoopFileURL() -> URL {
        let directory = getLooperRecordingsDirectory()
        let filename = "loop_\(Int(Date().timeIntervalSince1970)).wav"
        return directory.appendingPathComponent(filename)
    }
    
    static func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    static func levelToDecibels(_ level: Float) -> Float {
        if level <= 0 {
            return -96.0 // Minimum dB level
        }
        return 20 * log10(level)
    }
    
    static func decibelsToLevel(_ decibels: Float) -> Float {
        if decibels <= -96.0 {
            return 0.0
        }
        return pow(10, decibels / 20)
    }
    
    static func normalizeAudioLevel(_ level: Float) -> Float {
        // Normalize level from 0.0 to 1.0 for UI display
        let dbLevel = levelToDecibels(level)
        let normalizedDB = max(-60.0, dbLevel) // Clip at -60dB
        return (normalizedDB + 60.0) / 60.0 // Convert to 0.0-1.0 range
    }
} 