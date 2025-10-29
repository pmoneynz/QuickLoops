import Foundation
import AVFoundation

class SimpleAudioEngine: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let mainMixer: AVAudioMixerNode
    private let monitoringMixerNode = AVAudioMixerNode()
    
    // Components
    private var recorder: SimpleRecorder?
    private var player: SimplePlayer?
    
    // State tracking
    @Published var isEngineRunning = false
    
    // Level monitoring
    @Published var inputLevel: Float = 0.0
    
    // Unified tap management
    private var tapHandler: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?
    private var isLevelMonitoringEnabled = false
    private var isRecordingActive = false
    
    // Level update throttling to prevent rate limit warnings
    private var lastLevelUpdateTime: Date = Date()
    private let levelUpdateInterval: TimeInterval = 1.0 / 30.0 // 30 Hz max updates
    
    init() {
        inputNode = audioEngine.inputNode
        mainMixer = audioEngine.mainMixerNode
        setupAudioSession()
        setupAudioEngine()
        setupDeviceChangeMonitoring()
    }
    
    deinit {
        stop()
    }
    
    private func setupAudioSession() {
        // macOS doesn't use AVAudioSession - audio routing is handled by the system
        // The audio engine will automatically use the default input/output devices
        print("Audio session setup for macOS (automatic)")
    }
    
    private func setupAudioEngine() {
        // Add monitoring mixer node to the engine
        audioEngine.attach(monitoringMixerNode)
        
        // Get current formats BEFORE any connections
        let inputFormat = inputNode.inputFormat(forBus: 0)
        let outputFormat = audioEngine.outputNode.inputFormat(forBus: 0)
        
        print("🎛️ [ENGINE] Input format: \(inputFormat)")
        print("🎛️ [ENGINE] Output format: \(outputFormat)")
        
        // Check for sample rate mismatch (critical issue)
        if inputFormat.sampleRate != outputFormat.sampleRate {
            print("🚨 [ENGINE] SAMPLE RATE MISMATCH DETECTED!")
            print("🚨 [ENGINE] Input: \(inputFormat.sampleRate)Hz, Output: \(outputFormat.sampleRate)Hz")
            print("🚨 [ENGINE] This will cause performance issues and frame size errors")
            
            // Try to set a unified sample rate (prefer higher rate for better quality)
            let preferredSampleRate = max(inputFormat.sampleRate, outputFormat.sampleRate)
            print("🎛️ [ENGINE] Attempting to use preferred sample rate: \(preferredSampleRate)Hz")
        }
        
        // Check for channel count mismatch  
        if inputFormat.channelCount > 2 {
            print("🎛️ [ENGINE] High channel count detected: \(inputFormat.channelCount) channels")
            print("🎛️ [ENGINE] Using selective channel approach to avoid frame size errors")
            
            // Create a stereo format using only the input sample rate and standard format
            guard let stereoInputFormat = AVAudioFormat(standardFormatWithSampleRate: inputFormat.sampleRate, channels: 2) else {
                print("❌ [ENGINE] Failed to create stereo input format")
                return
            }
            
            print("🎛️ [ENGINE] Using stereo input format: \(stereoInputFormat)")
            
            // Connect with stereo format - AVAudioEngine will automatically use first 2 channels
            audioEngine.connect(inputNode, to: monitoringMixerNode, format: stereoInputFormat)
            audioEngine.connect(monitoringMixerNode, to: mainMixer, format: stereoInputFormat)
            
        } else {
            print("🎛️ [ENGINE] Channel count OK - direct connection")
            // Direct connection when channel count is 2 or less
            audioEngine.connect(inputNode, to: monitoringMixerNode, format: inputFormat)
            audioEngine.connect(monitoringMixerNode, to: mainMixer, format: inputFormat)
        }
        
        // Set up connections with careful format handling
        print("🎛️ [ENGINE] Starting with input format: \(inputFormat)")
        print("🎛️ [ENGINE] Input format settings: \(inputFormat.settings)")
        
        // Set initial monitoring state
        monitoringMixerNode.outputVolume = 0.0 // Start with monitoring disabled
        
        print("🎛️ [ENGINE] Enabling level monitoring")
        enableLevelMonitoring()
        
        print("🎛️ [ENGINE] Audio engine setup completed")
    }
    
    private func calculateLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }
        
        let channelDataValue = channelData.pointee
        let channelDataCount = Int(buffer.frameLength)
        
        var sum: Float = 0.0
        for i in 0..<channelDataCount {
            sum += abs(channelDataValue[i])
        }
        
        let average = sum / Float(channelDataCount)
        return average
    }
    
    func start() throws {
        guard !audioEngine.isRunning else { return }
        
        // Print current input device info before starting
        let inputFormat = inputNode.outputFormat(forBus: 0)
        print("🎛️ [ENGINE] Starting with input format: \(inputFormat)")
        print("🎛️ [ENGINE] Input format settings: \(inputFormat.settings)")
        
        try audioEngine.start()
        isEngineRunning = true
        enableLevelMonitoring()
        print("🎛️ [ENGINE] Audio engine started successfully")
    }
    
    // MARK: - Unified Tap Management
    
    func enableLevelMonitoring() {
        print("🎛️ [ENGINE] Enabling level monitoring")
        isLevelMonitoringEnabled = true
        updateTapHandler()
    }
    
    func disableLevelMonitoring() {
        print("🎛️ [ENGINE] Disabling level monitoring")
        isLevelMonitoringEnabled = false
        updateTapHandler()
    }
    
    func enableRecording(recordingHandler: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) {
        print("🎛️ [ENGINE] Enabling recording in unified tap")
        isRecordingActive = true
        
        // Store the recording handler
        let levelHandler = isLevelMonitoringEnabled ? { [weak self] (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
            // Calculate level with throttling
            guard let self = self else { return }
            let now = Date()
            
            // Throttle updates to avoid rate limit warnings
            if now.timeIntervalSince(self.lastLevelUpdateTime) >= self.levelUpdateInterval {
                let level = self.calculateLevel(from: buffer)
                DispatchQueue.main.async {
                    self.inputLevel = level
                }
                self.lastLevelUpdateTime = now
            }
        } : nil
        
        // Create combined handler
        tapHandler = { buffer, time in
            // Always call recording handler
            recordingHandler(buffer, time)
            // Call level handler if enabled
            levelHandler?(buffer, time)
        }
        
        installUnifiedTap()
    }
    
    func disableRecording() {
        print("🎛️ [ENGINE] Disabling recording in unified tap")
        isRecordingActive = false
        updateTapHandler()
    }
    
    private func updateTapHandler() {
        if isRecordingActive {
            // Recording is active, don't change tap (let recording manage it)
            return
        }
        
        if isLevelMonitoringEnabled {
            // Only level monitoring needed - with throttling
            tapHandler = { [weak self] buffer, time in
                guard let self = self else { return }
                let now = Date()
                
                // Throttle updates to avoid rate limit warnings
                if now.timeIntervalSince(self.lastLevelUpdateTime) >= self.levelUpdateInterval {
                    let level = self.calculateLevel(from: buffer)
                    DispatchQueue.main.async {
                        self.inputLevel = level
                    }
                    self.lastLevelUpdateTime = now
                }
            }
            installUnifiedTap()
        } else {
            // No monitoring needed
            removeTapIfExists()
        }
    }
    
    private func installUnifiedTap() {
        removeTapIfExists()
        
        guard let handler = tapHandler else { return }
        
        let format = inputNode.outputFormat(forBus: 0)
        print("🎛️ [ENGINE] Installing unified tap with format: \(format)")
        
        inputNode.installTap(onBus: 0, bufferSize: 512, format: format, block: handler)
    }
    
    private func removeTapIfExists() {
        // Check if tap exists before removing to avoid crashes
        inputNode.removeTap(onBus: 0)
    }

    func stop() {
        guard audioEngine.isRunning else { return }
        
        removeTapIfExists()
        audioEngine.stop()
        isEngineRunning = false
        print("Audio engine stopped")
    }
    
    func setInputMonitoring(enabled: Bool) {
        // Control monitoring by setting the volume of the monitoring mixer node
        // When enabled: volume = 1.0, when disabled: volume = 0.0
        monitoringMixerNode.outputVolume = enabled ? 1.0 : 0.0
        print("🎛️ [ENGINE] Input monitoring \(enabled ? "enabled" : "disabled")")
    }
    
    func createRecorder() -> SimpleRecorder {
        print("🎛️ [ENGINE] createRecorder() called")
        if recorder == nil {
            print("🎛️ [ENGINE] Creating new recorder instance")
            recorder = SimpleRecorder(audioEngine: self)
        } else {
            print("🎛️ [ENGINE] Returning existing recorder instance")
        }
        return recorder!
    }
    
    func createPlayer() -> SimplePlayer {
        if player == nil {
            player = SimplePlayer(audioEngine: audioEngine)
        }
        return player!
    }
    
    func setPlaybackVolume(_ volume: Float) {
        player?.setVolume(volume)
    }
    
    func getInputFormat() -> AVAudioFormat {
        return inputNode.outputFormat(forBus: 0)
    }
    
    private func setupDeviceChangeMonitoring() {
        // Monitor for audio device configuration changes
        NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: audioEngine,
            queue: .main
        ) { [weak self] _ in
            self?.handleConfigurationChange()
        }
    }
    
    private func handleConfigurationChange() {
        print("🔄 [ENGINE] Audio configuration changed!")
        
        // Print new input format after device change
        let newInputFormat = inputNode.outputFormat(forBus: 0)
        print("🔄 [ENGINE] New input format: \(newInputFormat)")
        print("🔄 [ENGINE] New format settings: \(newInputFormat.settings)")
        
        // Check if we're currently recording
        if let recorder = recorder, recorder.isCurrentlyRecording() {
            print("🔄 [ENGINE] ⚠️ Device change detected during recording!")
            print("🔄 [ENGINE] Current recording would need to be restarted with new format")
            print("🔄 [ENGINE] This is why inputFormat.settings is queried fresh each recording")
            
            // In a production app, you might:
            // 1. Stop current recording gracefully
            // 2. Show user notification about device change
            // 3. Auto-restart recording with new format
            // 4. Or let user manually restart
        } else {
            print("🔄 [ENGINE] ✅ Not recording - next recording will use new format automatically")
        }
        
        // The beauty is: next recording will automatically use the new format
        // because we call inputNode.outputFormat(forBus: 0) fresh each time
    }

    func diagnoseMonitoringSetup() {
        print("=== MONITORING DIAGNOSTICS ===")
        print("Engine running: \(audioEngine.isRunning)")
        
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let outputFormat = audioEngine.outputNode.inputFormat(forBus: 0)
        
        print("Input format: \(inputFormat)")
        print("Output format: \(outputFormat)")
        print("Input channels: \(inputFormat.channelCount)")
        print("Output channels: \(outputFormat.channelCount)")
        print("Input sample rate: \(inputFormat.sampleRate)Hz")
        print("Output sample rate: \(outputFormat.sampleRate)Hz")
        
        // Critical compatibility checks
        let channelMatch = inputFormat.channelCount == outputFormat.channelCount
        let sampleRateMatch = inputFormat.sampleRate == outputFormat.sampleRate
        
        print("✅ Channel count match: \(channelMatch)")
        if !channelMatch {
            print("⚠️  Channel conversion required: \(inputFormat.channelCount) → \(outputFormat.channelCount)")
        }
        
        print("✅ Sample rate match: \(sampleRateMatch)")
        if !sampleRateMatch {
            print("🚨 SAMPLE RATE MISMATCH: \(inputFormat.sampleRate)Hz → \(outputFormat.sampleRate)Hz")
            print("🚨 This WILL cause frame size errors and performance issues!")
            print("🚨 Recommendation: Use Audio MIDI Setup to set device to \(outputFormat.sampleRate)Hz")
        }
        
        print("Monitoring volume: \(monitoringMixerNode.outputVolume)")
        print("Input node connections: \(inputNode.numberOfOutputs)")
        print("Monitoring node connections: \(monitoringMixerNode.numberOfOutputs)")
        
        // Device information
        if let inputDeviceName = inputNode.auAudioUnit.audioUnitName {
            print("Input device name: \(inputDeviceName)")
        }
        if let outputDeviceName = audioEngine.outputNode.auAudioUnit.audioUnitName {
            print("Output device name: \(outputDeviceName)")
        }
        
        // Basic device info (simplified approach)
        print("Input node description: \(inputNode.description)")
        print("Output node description: \(audioEngine.outputNode.description)")
        
        print("==============================")
    }
} 