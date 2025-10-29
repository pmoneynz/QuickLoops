import Foundation
import AVFoundation

class SimplePlayer: ObservableObject {
    private let audioEngine: AVAudioEngine
    private var playerNode: AVAudioPlayerNode
    private var varispeedUnit: AVAudioUnitVarispeed
    private var audioFile: AVAudioFile?
    private var isPlaying = false
    private var currentURL: URL?
    private var currentRate: Float = 1.0
    
    init(audioEngine: AVAudioEngine) {
        self.audioEngine = audioEngine
        self.playerNode = AVAudioPlayerNode()
        self.varispeedUnit = AVAudioUnitVarispeed()
        
        // Attach player node and varispeed unit to the audio engine
        audioEngine.attach(playerNode)
        audioEngine.attach(varispeedUnit)
        
        // Connect player node to varispeed unit, then varispeed unit to main mixer
        audioEngine.connect(playerNode, to: varispeedUnit, format: nil)
        audioEngine.connect(varispeedUnit, to: audioEngine.mainMixerNode, format: nil)
        
        // Initialize varispeed unit with normal speed (rate 1.0)
        varispeedUnit.rate = 1.0
        currentRate = 1.0
    }
    
    func loadAudioFile(url: URL) throws {
        audioFile = try AVAudioFile(forReading: url)
        currentURL = url
        print("Audio file loaded: \(url)")
    }
    
    func startPlaying() throws {
        guard audioFile != nil, !isPlaying else { return }
        
        // Schedule the audio file for looping playback
        scheduleLoop()
        
        playerNode.play()
        isPlaying = true
        print("Playback started with looping")
    }
    
    func stopPlaying() {
        guard isPlaying else { return }
        
        playerNode.stop()
        isPlaying = false
        print("Playback stopped")
    }
    
    func restartPlaying() throws {
        guard audioFile != nil else { return }
        
        // Stop current playback if playing
        if isPlaying {
            playerNode.stop()
            isPlaying = false
        }
        
        // Reschedule from the beginning and start
        scheduleLoop()
        playerNode.play()
        isPlaying = true
        print("Playback restarted from beginning")
    }
    
    private func scheduleLoop() {
        guard let audioFile = audioFile else { return }
        
        // Schedule the file to play with completion handler for looping
        playerNode.scheduleFile(audioFile, at: nil) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self, self.isPlaying else { return }
                // Reschedule the same file for continuous looping
                self.scheduleLoop()
            }
        }
    }
    
    func setVolume(_ volume: Float) {
        playerNode.volume = volume
    }
    
    func isCurrentlyPlaying() -> Bool {
        return isPlaying
    }
    
    func getCurrentFileURL() -> URL? {
        return currentURL
    }
    
    func clearAudioFile() {
        stopPlaying()
        audioFile = nil
        currentURL = nil
        // Reset varispeed to normal when clearing
        adjustPitch(to: 1.0)
    }
    
    func adjustPitch(by delta: Float) {
        let newRate = currentRate + delta
        adjustPitch(to: newRate)
    }
    
    func adjustPitch(to rate: Float) {
        // Clamp rate to range 0.8 to 1.2 (±20%)
        let clampedRate = max(0.8, min(1.2, rate))
        currentRate = clampedRate
        varispeedUnit.rate = clampedRate
        
        // AVAudioUnitVarispeed supports real-time rate changes, so we don't need to reschedule
        print("Varispeed adjusted to \(clampedRate) (\(String(format: "%.1f", (clampedRate - 1.0) * 100))%)")
    }
    
    func getCurrentRate() -> Float {
        return currentRate
    }
} 