import Foundation
import AVFoundation

class SimplePlayer: ObservableObject {
    private let audioEngine: AVAudioEngine
    private var playerNode: AVAudioPlayerNode
    private var audioFile: AVAudioFile?
    private var isPlaying = false
    private var currentURL: URL?
    
    init(audioEngine: AVAudioEngine) {
        self.audioEngine = audioEngine
        self.playerNode = AVAudioPlayerNode()
        
        // Attach player node to the audio engine
        audioEngine.attach(playerNode)
        
        // Connect player node to main mixer
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
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
    }
} 