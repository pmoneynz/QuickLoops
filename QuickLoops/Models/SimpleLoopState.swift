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
    @Published var varispeedRate: Float = 1.0
    
    // Save/Load state properties
    @Published var currentSavedLoop: SavedLoop?
    @Published var showingSaveDialog = false
    @Published var showingLoopLibrary = false
    
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
    
    // Save/Load computed properties
    var canSave: Bool { 
        return hasAudio && transportState == .stopped && currentSavedLoop == nil 
    }

    var isCurrentLoopSaved: Bool {
        return currentSavedLoop != nil
    }

    var canLoad: Bool {
        return transportState == .stopped
    }
    
    var varispeedPercentage: Float {
        return (varispeedRate - 1.0) * 100
    }
} 