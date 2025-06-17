import Foundation
import AVFoundation
import Combine

class LoopPreviewEngine: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private var playerNode: AVAudioPlayerNode
    private var currentFile: AVAudioFile?
    
    @Published var isPlaying = false
    @Published var currentPreviewLoop: SavedLoop?
    
    var previewVolume: Float = 0.7 {
        didSet {
            playerNode.volume = previewVolume
        }
    }
    
    private var engineStarted = false
    
    init() {
        self.playerNode = AVAudioPlayerNode()
        setupAudioEngine()
    }
    
    deinit {
        cleanup()
    }
    
    private func setupAudioEngine() {
        // Attach player node to the audio engine
        audioEngine.attach(playerNode)
        
        // Connect player node directly to output (bypass main mixer for isolation)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
        
        // Set initial volume
        playerNode.volume = previewVolume
    }
    
    private func startEngineIfNeeded() throws {
        guard !engineStarted else { return }
        
        try audioEngine.start()
        engineStarted = true
        print("🎵 [PREVIEW] Preview engine started")
    }
    
    func previewLoop(_ loop: SavedLoop) throws {
        // Stop any current preview
        stopPreview()
        
        // Start engine if needed
        try startEngineIfNeeded()
        
        // Load the audio file
        do {
            currentFile = try AVAudioFile(forReading: loop.fileURL)
            currentPreviewLoop = loop
            
            // Schedule file for single playback (no looping)
            playerNode.scheduleFile(currentFile!, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    self?.handlePlaybackCompletion()
                }
            }
            
            // Start playback
            playerNode.play()
            isPlaying = true
            
            print("🎵 [PREVIEW] Started previewing: \(loop.name)")
            
        } catch {
            currentFile = nil
            currentPreviewLoop = nil
            throw error
        }
    }
    
    func stopPreview() {
        guard isPlaying else { return }
        
        playerNode.stop()
        isPlaying = false
        currentFile = nil
        currentPreviewLoop = nil
        
        print("🎵 [PREVIEW] Stopped preview")
    }
    
    func setPreviewVolume(_ volume: Float) {
        previewVolume = max(0.0, min(1.0, volume))
    }
    
    private func handlePlaybackCompletion() {
        // Preview finished naturally
        isPlaying = false
        currentFile = nil
        currentPreviewLoop = nil
        
        print("🎵 [PREVIEW] Preview completed")
    }
    
    private func cleanup() {
        stopPreview()
        
        if engineStarted {
            audioEngine.stop()
            engineStarted = false
        }
        
        print("🎵 [PREVIEW] Preview engine cleaned up")
    }
    
    // MARK: - Helper Methods
    
    func isPreviewingLoop(_ loop: SavedLoop) -> Bool {
        return isPlaying && currentPreviewLoop?.id == loop.id
    }
} 