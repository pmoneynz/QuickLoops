import Foundation
import AVFoundation

class SimpleRecorder: ObservableObject {
    private let audioEngine: SimpleAudioEngine
    private var audioFile: AVAudioFile?
    private var isRecording = false
    
    @Published var recordingURL: URL?
    
    init(audioEngine: SimpleAudioEngine) {
        self.audioEngine = audioEngine
    }
    
    func startRecording() throws {
        print("📼 [RECORDER] startRecording() called")
        guard !isRecording else { 
            print("📼 [RECORDER] Already recording, returning")
            return 
        }
        
        // Get input format from audio engine (we don't need direct access to inputNode anymore)
        // The unified tap system handles format detection internally
        let inputFormat = audioEngine.getInputFormat()
        print("📼 [RECORDER] Input format: \(inputFormat)")
        
        // Create output file URL
        let outputURL = AudioUtils.createLoopFileURL()
        recordingURL = outputURL
        print("📼 [RECORDER] Recording URL created: \(outputURL)")
        
        // Create the audio file for recording - match the input format
        // Use the same format as input to avoid conversion errors
        print("📼 [RECORDER] Creating audio file with input format to avoid conversion")
        
        do {
            audioFile = try AVAudioFile(forWriting: outputURL, settings: inputFormat.settings)
            print("📼 [RECORDER] Audio file created successfully with format: \(inputFormat)")
        } catch {
            print("❌ [RECORDER ERROR] Failed to create audio file: \(error)")
            print("❌ [RECORDER ERROR] Input format settings: \(inputFormat.settings)")
            throw error
        }
        
        // Use unified tap system instead of managing our own tap
        print("📼 [RECORDER] Using unified tap system for recording")
        var bufferCount = 0
        
        let recordingHandler: (AVAudioPCMBuffer, AVAudioTime) -> Void = { [weak self] buffer, time in
            guard let self = self, let audioFile = self.audioFile else { return }
            
            // Debug: Print buffer info occasionally (every 100th buffer to avoid rate limiting)
            bufferCount += 1
            let frameCount = buffer.frameLength
            if bufferCount % 100 == 0 && frameCount > 0 {
                print("📼 [RECORDER TAP] Writing buffer #\(bufferCount) with \(frameCount) frames")
            }
            
            do {
                try audioFile.write(from: buffer)
                // Success - only log first successful write
                if bufferCount == 1 {
                    print("📼 [RECORDER TAP] ✅ First buffer written successfully!")
                }
            } catch {
                print("❌ [RECORDER TAP ERROR] Error writing audio buffer #\(bufferCount): \(error)")
            }
        }
        
        // Enable recording in the unified tap system
        audioEngine.enableRecording(recordingHandler: recordingHandler)
        
        isRecording = true
        print("📼 [RECORDER] Recording started successfully to: \(outputURL)")
        print("📼 [RECORDER] isRecording = \(isRecording)")
    }
    
    func stopRecording() {
        print("📼 [RECORDER] stopRecording() called")
        guard isRecording else { 
            print("📼 [RECORDER] Not recording, returning")
            return 
        }
        
        // Disable recording in unified tap system (level monitoring continues)
        print("📼 [RECORDER] Disabling recording in unified tap system")
        audioEngine.disableRecording()
        
        // Close the audio file to ensure it's written to disk
        if audioFile != nil {
            print("📼 [RECORDER] Closing audio file")
            // AVAudioFile doesn't have an explicit close method, setting to nil will close it
        }
        
        audioFile = nil
        isRecording = false
        print("📼 [RECORDER] Recording stopped - isRecording = \(isRecording)")
        
        if let url = recordingURL {
            print("📼 [RECORDER] Final recording URL: \(url)")
        }
    }
    
    func isCurrentlyRecording() -> Bool {
        return isRecording
    }
    
    func getRecordingURL() -> URL? {
        return recordingURL
    }
    
    func clearRecording() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
    }
} 