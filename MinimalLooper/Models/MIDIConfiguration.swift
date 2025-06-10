import Foundation

struct MIDIConfiguration: Codable, Equatable {
    var recordNote: UInt8 = 80    // G#5
    var playNote: UInt8 = 0      // D4
    var stopNote: UInt8 = 1      // E4
    var clearNote: UInt8 = 2     // F4
    
    private static let userDefaultsKey = "MIDIConfiguration"
    
    // MARK: - Helper Methods
    
    func noteForAction(_ action: TransportAction) -> UInt8 {
        switch action {
        case .record: return recordNote
        case .play: return playNote
        case .stop: return stopNote
        case .clear: return clearNote
        }
    }
    
    mutating func setNote(_ note: UInt8, for action: TransportAction) {
        switch action {
        case .record: recordNote = note
        case .play: playNote = note
        case .stop: stopNote = note
        case .clear: clearNote = note
        }
    }
    
    func actionForNote(_ note: UInt8) -> TransportAction? {
        switch note {
        case recordNote: return .record
        case playNote: return .play
        case stopNote: return .stop
        case clearNote: return .clear
        default: return nil
        }
    }
    
    // MARK: - Persistence
    
    static func load() -> MIDIConfiguration {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let configuration = try? JSONDecoder().decode(MIDIConfiguration.self, from: data) else {
            return MIDIConfiguration() // Return default configuration
        }
        return configuration
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        } catch {
            print("Failed to save MIDI configuration: \(error)")
        }
    }
}

enum TransportAction: String, CaseIterable, Codable {
    case record, play, stop, clear
    
    var displayName: String {
        switch self {
        case .record: return "Record"
        case .play: return "Play"
        case .stop: return "Stop"
        case .clear: return "Clear"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .record: return "record.circle"
        case .play: return "play.circle"
        case .stop: return "stop.circle"
        case .clear: return "trash.circle"
        }
    }
} 