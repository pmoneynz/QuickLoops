import Foundation

enum TransportState {
    case stopped
    case recording  
    case playing
}

class SimpleLoopState: ObservableObject {
    @Published var transportState: TransportState = .stopped
    @Published var hasAudio: Bool = false
    @Published var isRecording: Bool = false
    @Published var fileURL: URL?
    @Published var inputLevel: Float = 0.0
    @Published var playbackVolume: Float = 1.0
    @Published var inputMonitoringEnabled: Bool = false
    
    // Helper computed properties
    var canRecord: Bool {
        return transportState == .stopped
    }
    
    var canPlay: Bool {
        return hasAudio && transportState == .stopped
    }
    
    var canStop: Bool {
        return transportState == .recording || transportState == .playing
    }
    
    var canClear: Bool {
        return hasAudio && transportState == .stopped
    }
} 