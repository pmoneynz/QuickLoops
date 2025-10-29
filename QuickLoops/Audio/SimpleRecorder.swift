import Foundation
import AVFoundation
import AudioToolbox

class SimpleRecorder: ObservableObject {
    private let audioEngine: SimpleAudioEngine
    private var audioFile: AVAudioFile?
    private var isRecording = false
    private var stopRequested = false
    private var recordingStartTime: AVAudioTime?
    private var recordingStartSample: AVAudioFramePosition = 0
    private var stopSample: AVAudioFramePosition?
    private var sampleRate: Double = 0.0
    
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
        self.sampleRate = inputFormat.sampleRate
        
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
        
        // Reset recording state
        recordingStartTime = nil
        recordingStartSample = 0
        stopSample = nil
        stopRequested = false
        
        // Use unified tap system instead of managing our own tap
        print("📼 [RECORDER] Using unified tap system for recording")
        var bufferCount = 0
        
        let recordingHandler: (AVAudioPCMBuffer, AVAudioTime) -> Void = { [weak self] buffer, time in
            guard let self = self, let audioFile = self.audioFile else { return }

            // Capture recording start time on first buffer
            if self.recordingStartTime == nil {
                self.recordingStartTime = time
                // Resolve start sample position
                if time.isSampleTimeValid {
                    self.recordingStartSample = time.sampleTime
                } else if time.isHostTimeValid {
                    let seconds = AVAudioTime.seconds(forHostTime: time.hostTime)
                    let samples = seconds * self.sampleRate
                    self.recordingStartSample = AVAudioFramePosition(samples.rounded())
                }
                print("📼 [RECORDER] Recording started at sample: \(self.recordingStartSample)")
            }

            // Calculate relative position from recording start
            let relativeStartSample: AVAudioFramePosition = {
                if time.isSampleTimeValid {
                    return time.sampleTime - self.recordingStartSample
                } else if time.isHostTimeValid, let startTime = self.recordingStartTime, startTime.isHostTimeValid {
                    let startSeconds = AVAudioTime.seconds(forHostTime: startTime.hostTime)
                    let currentSeconds = AVAudioTime.seconds(forHostTime: time.hostTime)
                    let elapsedSeconds = currentSeconds - startSeconds
                    return AVAudioFramePosition(elapsedSeconds * self.sampleRate)
                } else {
                    // Fallback: estimate from buffer count (rough)
                    // bufferCount is current count before this buffer, so multiply by frameLength
                    return AVAudioFramePosition(bufferCount) * AVAudioFramePosition(buffer.frameLength)
                }
            }()

            // Debug: Print buffer info occasionally (every 100th buffer to avoid rate limiting)
            bufferCount += 1
            let frameCount = buffer.frameLength
            if bufferCount % 100 == 0 && frameCount > 0 {
                print("📼 [RECORDER TAP] Writing buffer #\(bufferCount) with \(frameCount) frames, relative sample: \(relativeStartSample)")
            }

            var framesToWrite = frameCount
            if let stopSample = self.stopSample, stopSample >= 0 {
                let bufferEndExclusive = relativeStartSample + AVAudioFramePosition(frameCount)
                if stopSample <= relativeStartSample {
                    framesToWrite = 0
                } else if stopSample < bufferEndExclusive {
                    framesToWrite = AVAudioFrameCount(stopSample - relativeStartSample)
                    print("📼 [RECORDER] Trimming buffer: writing \(framesToWrite) of \(frameCount) frames")
                }
            }

            if framesToWrite > 0 {
                if framesToWrite == frameCount {
                    do {
                        try audioFile.write(from: buffer)
                        if bufferCount == 1 {
                            print("📼 [RECORDER TAP] ✅ First buffer written successfully!")
                        }
                    } catch {
                        print("❌ [RECORDER TAP ERROR] Error writing audio buffer #\(bufferCount): \(error)")
                    }
                } else if let trimmed = self.makeTrimmedBuffer(from: buffer, framesToWrite: framesToWrite) {
                    do {
                        try audioFile.write(from: trimmed)
                        print("📼 [RECORDER] Wrote trimmed buffer: \(framesToWrite) frames")
                    } catch {
                        print("❌ [RECORDER TAP ERROR] Error writing trimmed buffer #\(bufferCount): \(error)")
                    }
                }
            }

            // If we've reached/passed stop, finalize on main thread
            if let stopSample = self.stopSample {
                let bufferEndExclusive = relativeStartSample + AVAudioFramePosition(frameCount)
                if bufferEndExclusive >= stopSample {
                    DispatchQueue.main.async {
                        self.audioEngine.disableRecording()
                        if self.audioFile != nil {
                            self.audioFile = nil
                        }
                        self.isRecording = false
                        print("📼 [RECORDER] Precisely stopped at relative sample \(stopSample) (after \(bufferCount) buffers)")
                    }
                    return // Don't process more buffers
                }
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

        // Capture precise stop time and calculate relative to recording start
        stopRequested = true
        let stopHostTime = AudioGetCurrentHostTime()
        
        if let startTime = recordingStartTime {
            if startTime.isHostTimeValid {
                let startSeconds = AVAudioTime.seconds(forHostTime: startTime.hostTime)
                let stopSeconds = AVAudioTime.seconds(forHostTime: stopHostTime)
                let elapsedSeconds = stopSeconds - startSeconds
                stopSample = AVAudioFramePosition(elapsedSeconds * sampleRate)
                print("📼 [RECORDER] Stop requested: elapsed \(elapsedSeconds)s = \(String(describing: stopSample)) samples")
            } else if startTime.isSampleTimeValid {
                // Calculate from sample time difference
                let startSeconds = Double(startTime.sampleTime) / sampleRate
                let stopSeconds = AVAudioTime.seconds(forHostTime: stopHostTime)
                let elapsedSeconds = stopSeconds - startSeconds
                stopSample = AVAudioFramePosition(elapsedSeconds * sampleRate)
                print("📼 [RECORDER] Stop requested: elapsed \(elapsedSeconds)s = \(String(describing: stopSample)) samples")
            } else {
                // Fallback: disable immediately (not ideal but safe)
                print("⚠️ [RECORDER] Cannot calculate precise stop, disabling immediately")
                audioEngine.disableRecording()
                audioFile = nil
                isRecording = false
            }
        } else {
            // Recording start not captured yet - disable immediately
            print("⚠️ [RECORDER] Stop requested before first buffer, disabling immediately")
            audioEngine.disableRecording()
            audioFile = nil
            isRecording = false
        }

        // Do not disable recording or nil the file here if stopSample was calculated.
        // The tap will trim and finalize precisely at the requested sample.
    }

    private func makeTrimmedBuffer(from source: AVAudioPCMBuffer, framesToWrite: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        guard framesToWrite > 0 else { return nil }

        let format = source.format
        guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesToWrite) else { return nil }
        out.frameLength = framesToWrite

        let channels = Int(format.channelCount)
        let frames = Int(framesToWrite)

        // Non-interleaved float
        if let src = source.floatChannelData, let dst = out.floatChannelData {
            for ch in 0..<channels {
                memcpy(dst[ch], src[ch], frames * MemoryLayout<Float>.size)
            }
            return out
        }

        // Non-interleaved Int16
        if let srcI16 = source.int16ChannelData, let dstI16 = out.int16ChannelData {
            for ch in 0..<channels {
                memcpy(dstI16[ch], srcI16[ch], frames * MemoryLayout<Int16>.size)
            }
            return out
        }

        // Non-interleaved Int32
        if let srcI32 = source.int32ChannelData, let dstI32 = out.int32ChannelData {
            for ch in 0..<channels {
                memcpy(dstI32[ch], srcI32[ch], frames * MemoryLayout<Int32>.size)
            }
            return out
        }

        // Interleaved formats: memcpy raw bytes
        let bytesPerFrame = Int(format.streamDescription.pointee.mBytesPerFrame)
        let byteCount = frames * bytesPerFrame

        let srcList = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer<AudioBufferList>(mutating: source.audioBufferList))
        let dstList = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer<AudioBufferList>(mutating: out.audioBufferList))
        guard srcList.count == dstList.count else { return nil }
        for i in 0..<srcList.count {
            guard let srcPtr = srcList[i].mData, let dstPtr = dstList[i].mData else { return nil }
            memcpy(dstPtr, srcPtr, byteCount)
        }

        return out
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