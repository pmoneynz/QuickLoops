import Foundation
import SwiftUI
import Combine

class SimpleLooperViewModel: ObservableObject {
    @Published var loopState = SimpleLoopState()
    
    private let audioEngine = SimpleAudioEngine()
    private var recorder: SimpleRecorder?
    private var player: SimplePlayer?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupObservers()
        startAudioEngine()
    }
    
    private func setupObservers() {
        // Observe input level from audio engine
        audioEngine.$inputLevel
            .receive(on: DispatchQueue.main)
            .assign(to: \.loopState.inputLevel, on: self)
            .store(in: &cancellables)
        
        // Forward loopState changes to trigger UI updates
        loopState.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func startAudioEngine() {
        do {
            try audioEngine.start()
            // Set initial monitoring state
            audioEngine.setInputMonitoring(enabled: loopState.inputMonitoringEnabled)
        } catch {
            print("Failed to start audio engine: \(error)")
            // TODO: Show user alert
        }
    }
    
    // MARK: - Transport Control Actions
    
    func recordButtonPressed() {
        print("🔴 [DEBUG] Record button pressed - current state: \(loopState.transportState)")
        switch loopState.transportState {
        case .stopped:
            print("🔴 [DEBUG] Starting recording from stopped state")
            startRecording()
        case .recording:
            print("🔴 [DEBUG] Stopping recording and starting playback")
            stopRecordingAndStartPlayback()
        case .playing:
            print("🔴 [DEBUG] Record button pressed while playing (should not happen)")
            break // Should not be reachable when recording button is enabled
        }
    }
    
    func playButtonPressed() {
        guard loopState.hasAudio else { return }
        
        switch loopState.transportState {
        case .stopped:
            startPlayback()
        case .playing:
            stopPlayback()
        case .recording:
            break // Should not be reachable when play button is enabled
        }
    }
    
    func stopButtonPressed() {
        switch loopState.transportState {
        case .recording:
            stopRecording()
        case .playing:
            stopPlayback()
        case .stopped:
            break // Already stopped
        }
    }
    
    func clearButtonPressed() {
        guard loopState.canClear else { return }
        clearLoop()
    }
    
    func setPlaybackVolume(_ volume: Float) {
        loopState.playbackVolume = volume
        audioEngine.setPlaybackVolume(volume)
    }
    
    func toggleInputMonitoring() {
        loopState.inputMonitoringEnabled.toggle()
        audioEngine.setInputMonitoring(enabled: loopState.inputMonitoringEnabled)
    }
    
    // MARK: - Private Implementation
    
    private func startRecording() {
        print("🎤 [DEBUG] startRecording() called")
        do {
            print("🎤 [DEBUG] Creating recorder from audio engine")
            recorder = audioEngine.createRecorder()
            print("🎤 [DEBUG] Recorder created, attempting to start recording")
            try recorder?.startRecording()
            
            print("🎤 [DEBUG] Recording started successfully, updating state")
            loopState.transportState = .recording
            loopState.isRecording = true
            print("🎤 [DEBUG] State updated - transportState: \(loopState.transportState), isRecording: \(loopState.isRecording)")
        } catch {
            print("❌ [ERROR] Failed to start recording: \(error)")
            print("❌ [ERROR] Error details: \(error.localizedDescription)")
            // TODO: Show user alert
        }
    }
    
    private func stopRecording() {
        print("🛑 [DEBUG] stopRecording() called")
        recorder?.stopRecording()
        
        print("🛑 [DEBUG] Updating state to stopped")
        loopState.transportState = .stopped
        loopState.isRecording = false
        
        if let recordingURL = recorder?.getRecordingURL() {
            print("🛑 [DEBUG] Recording URL found: \(recordingURL)")
            print("🛑 [DEBUG] Checking if file exists at URL...")
            let fileExists = FileManager.default.fileExists(atPath: recordingURL.path)
            print("🛑 [DEBUG] File exists: \(fileExists)")
            
            if fileExists {
                do {
                    let fileSize = try FileManager.default.attributesOfItem(atPath: recordingURL.path)[.size] as? Int64 ?? 0
                    print("🛑 [DEBUG] File size: \(fileSize) bytes")
                } catch {
                    print("❌ [ERROR] Could not get file size: \(error)")
                }
            }
            
            loopState.fileURL = recordingURL
            loopState.hasAudio = true
            print("🛑 [DEBUG] Loop state updated - hasAudio: \(loopState.hasAudio)")
        } else {
            print("❌ [ERROR] No recording URL found!")
        }
        
        print("🛑 [DEBUG] Recording stopped")
    }
    
    private func stopRecordingAndStartPlayback() {
        stopRecording()
        
        // Small delay to ensure file is properly written
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startPlayback()
        }
    }
    
    private func startPlayback() {
        guard let fileURL = loopState.fileURL else { return }
        
        do {
            player = audioEngine.createPlayer()
            try player?.loadAudioFile(url: fileURL)
            try player?.startPlaying()
            
            // Set the current volume
            player?.setVolume(loopState.playbackVolume)
            
            loopState.transportState = .playing
            print("Playback started")
        } catch {
            print("Failed to start playback: \(error)")
            // TODO: Show user alert
        }
    }
    
    private func stopPlayback() {
        player?.stopPlaying()
        loopState.transportState = .stopped
        print("Playback stopped")
    }
    
    private func clearLoop() {
        // Stop any current playback
        stopPlayback()
        
        // Clear the audio file
        player?.clearAudioFile()
        recorder?.clearRecording()
        
        // Reset state
        loopState.hasAudio = false
        loopState.fileURL = nil
        loopState.transportState = .stopped
        
        print("Loop cleared")
    }
} 