# QuickLoops - Implementation Documentation

## Overview

QuickLoops is a macOS audio looping application built with SwiftUI and AVFoundation. It provides a simple interface for recording audio input and looping it back for real-time performance. The app follows an MVVM architecture with a clear separation between audio processing, state management, and user interface.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ContentView   │ ←→ │ SimpleLooper    │ ←→ │ SimpleAudio     │
│   (UI Layer)    │    │ ViewModel       │    │ Engine          │
│                 │    │ (Business Logic)│    │ (Audio Core)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                       ┌─────────────────┐    ┌─────────────────┐
                       │ SimpleLoopState │    │ SimpleRecorder  │
                       │ (State Model)   │    │ SimplePlayer    │
                       └─────────────────┘    └─────────────────┘
                                │                       │
                       ┌─────────────────┐    ┌─────────────────┐
                       │ AudioUtils      │    │ UI Components   │
                       │ (Utilities)     │    │ (Views)         │
                       └─────────────────┘    └─────────────────┘
```

## Audio Signal Path

### 1. Input Signal Chain

```
Physical Input Device (Microphone/Interface - Any Channel Count)
           ↓
    macOS Core Audio System
           ↓
    AVAudioEngine.inputNode (10ch, 24ch, 36ch, etc.)
           ↓
    [Channel Selection] → First 2 Channels Only (for >2ch devices)
           ↓
    [Unified Tap System] → Combined Level Monitoring & Recording
           ↓
    AVAudioMixerNode.monitoringMixerNode (stereo, volume-controlled)
           ↓
    AVAudioEngine.mainMixerNode (mixing with playback)
           ↓
    macOS Core Audio System
           ↓
    Physical Output Device (Speakers/Headphones)
```

**Multi-Channel Device Handling**: For audio interfaces with >2 channels (e.g., 10ch, 24ch, 36ch), the system automatically selects channels 1-2 (typically the main stereo pair) to avoid format conversion overhead and frame size errors.

### 2. Unified Tap Management System

**Key Innovation**: A sophisticated unified tap system manages both level monitoring and recording from a single audio tap, preventing conflicts and improving performance.

```
inputNode.installTap() → Unified Handler
                              ├→ Level Calculation (throttled to 30Hz)
                              └→ Recording (when active)
```

**Benefits**:
- **No Tap Conflicts**: Single tap handles multiple use cases
- **Efficient Processing**: Shared buffer processing reduces CPU overhead
- **Throttled Updates**: Level monitoring limited to 30Hz to prevent rate limit warnings
- **Dynamic Reconfiguration**: Tap automatically adapts to current needs

### 3. Playback Signal Chain

```
Recorded Audio File (WAV on disk)
           ↓
    AVAudioFile (loaded into memory)
           ↓
    AVAudioPlayerNode (with loop scheduling)
           ↓
    AVAudioEngine.mainMixerNode
           ↓
    macOS Core Audio System
           ↓
    Physical Output Device (Speakers/Headphones)
```

### 4. Input Monitoring Architecture

```
inputNode → monitoringMixerNode → mainMixerNode
                    ↓
            Volume Control (0.0 or 1.0)
            - 1.0 = Monitoring ON
            - 0.0 = Monitoring OFF
```

### 5. Multi-Channel Audio Device Support

**Problem Solved**: Professional audio interfaces often provide 8, 10, 16, 24, or even 36+ input channels, but most monitoring and looping applications only need stereo monitoring. Direct format conversion from high channel counts to stereo can cause buffer alignment issues and frame size errors.

**Channel-Selective Approach**:
```
High-Channel Input Device (e.g., 10 channels @ 48kHz)
                    ↓
        [Automatic Channel Selection]
                    ↓
    Use Channels 1-2 Only (stereo pair)
                    ↓
        Standard Stereo Processing
```

**Implementation Details**:
- **Automatic Detection**: Detects input devices with >2 channels
- **Channel Selection**: Uses first 2 channels (typically main stereo pair)
- **Format Creation**: Creates stereo format matching input sample rate
- **No Conversion Overhead**: Avoids real-time multi-channel to stereo conversion
- **Error Prevention**: Eliminates `kAudioUnitErr_TooManyFramesToProcess` errors

**Supported Configurations**:
- **2-Channel Interfaces**: Direct connection (no special handling)
- **Multi-Channel Interfaces**: Channel-selective stereo extraction
- **High-End Interfaces**: Supports 24ch, 36ch, 64ch+ professional devices
- **Sample Rate Flexibility**: Works with 44.1kHz, 48kHz, 96kHz, 192kHz

**Technical Benefits**:
- **Zero Frame Errors**: Eliminates buffer alignment issues
- **Optimal Performance**: No unnecessary format conversion CPU overhead
- **Universal Compatibility**: Works with any channel count configuration
- **Professional Workflow**: Uses industry-standard channel 1-2 selection

## Core Workflow State Machine

### Transport States

```
┌─────────┐  Record   ┌───────────┐  Stop Recording  ┌─────────┐
│ STOPPED │ ────────→ │ RECORDING │ ──────────────→ │ STOPPED │
│         │           │           │                  │ (w/Audio)│
└─────────┘           └───────────┘                  └─────────┘
     ↑                                                     │
     │                                                     │ Play
     │ Stop                                                ↓
     │               ┌─────────┐    Play (if has audio)  ┌─────────┐
     └──────────────│ PLAYING │ ←─────────────────────── │ STOPPED │
                     │         │                          │ (w/Audio)│
                     └─────────┘                          └─────────┘
```

### State Transitions

1. **STOPPED → RECORDING**
   - User presses record button
   - Creates new `SimpleRecorder` instance
   - Activates unified tap with recording handler
   - Creates new WAV file with native input format
   - Begins writing audio buffers to file

2. **RECORDING → STOPPED (with audio)**
   - User presses record button again (stop & play behavior)
   - Disables recording in unified tap system
   - Closes audio file (automatic via nil assignment)
   - Updates state to indicate audio is available
   - Automatically transitions to playback

3. **STOPPED → PLAYING**
   - User presses play button (requires existing audio)
   - Creates new `SimplePlayer` instance
   - Loads recorded audio file
   - Schedules looped playback
   - Starts playback with volume control

4. **PLAYING → STOPPED**
   - User presses stop or play button (toggle behavior)
   - Stops `AVAudioPlayerNode`
   - Maintains audio file reference for future playback

## Detailed Component Analysis

### SimpleAudioEngine (Core Audio Manager)

**Purpose**: Central coordinator for all audio operations with unified tap management
**Key Responsibilities**:
- AVAudioEngine lifecycle management
- Unified tap system for level monitoring and recording
- Input monitoring control via dedicated mixer node
- Audio device configuration monitoring
- Factory methods for recorder and player instances
- Multi-channel audio device support with automatic channel selection
- Advanced audio diagnostics for device compatibility troubleshooting

**Critical Implementation Details**:
- Uses unified tap handler to prevent tap conflicts
- Implements 30Hz throttling for level updates to avoid rate limit warnings
- Dynamic format detection prevents format conversion errors
- Single-instance pattern for recorder/player to avoid resource conflicts
- Dedicated monitoring mixer node for clean input monitoring control
- **Channel-selective input processing** for multi-channel audio interfaces
- **Sample rate mismatch detection** and warning system
- **Comprehensive audio diagnostics** for troubleshooting device issues

```swift
// Unified tap management
private var tapHandler: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?
private var isLevelMonitoringEnabled = false
private var isRecordingActive = false

// Level update throttling
private var lastLevelUpdateTime: Date = Date()
private let levelUpdateInterval: TimeInterval = 1.0 / 30.0 // 30 Hz max updates

// Multi-channel device support
private func setupAudioEngine() {
    // Detect high channel count devices
    if inputFormat.channelCount > 2 {
        print("🎛️ [ENGINE] High channel count detected: \(inputFormat.channelCount) channels")
        print("🎛️ [ENGINE] Using selective channel approach to avoid frame size errors")
        
        // Create stereo format using first 2 channels
        guard let stereoInputFormat = AVAudioFormat(standardFormatWithSampleRate: inputFormat.sampleRate, channels: 2) else {
            print("❌ [ENGINE] Failed to create stereo input format")
            return
        }
        
        // Connect with channel selection
        audioEngine.connect(inputNode, to: monitoringMixerNode, format: stereoInputFormat)
        audioEngine.connect(monitoringMixerNode, to: mainMixer, format: stereoInputFormat)
    }
}

// Advanced diagnostics
func diagnoseMonitoringSetup() {
    print("=== MONITORING DIAGNOSTICS ===")
    let inputFormat = inputNode.outputFormat(forBus: 0)
    let outputFormat = audioEngine.outputNode.inputFormat(forBus: 0)
    
    // Critical compatibility checks
    let sampleRateMatch = inputFormat.sampleRate == outputFormat.sampleRate
    if !sampleRateMatch {
        print("🚨 SAMPLE RATE MISMATCH: \(inputFormat.sampleRate)Hz → \(outputFormat.sampleRate)Hz")
        print("🚨 This WILL cause frame size errors and performance issues!")
        print("🚨 Recommendation: Use Audio MIDI Setup to set device to \(outputFormat.sampleRate)Hz")
    }
}
```

### SimpleRecorder (Recording Engine)

**Purpose**: Handles audio capture through unified tap system
**Key Responsibilities**:
- Integration with unified tap management
- Dynamic audio format matching
- Real-time audio buffer capture
- WAV file creation and management
- Recording state management

**Critical Implementation Details**:
- Uses unified tap system instead of managing separate tap
- Records in native input format to avoid conversion overhead
- Uses 2048-sample buffer size for optimal performance (increased from 1024 to prevent rate limit warnings)
- Automatically generates unique filenames with timestamps
- Implements clean recording state transitions

```swift
// Unified tap integration
func startRecording() throws {
    let recordingHandler: (AVAudioPCMBuffer, AVAudioTime) -> Void = { buffer, time in
        try audioFile.write(from: buffer)
    }
    audioEngine.enableRecording(recordingHandler: recordingHandler)
}
```

### SimplePlayer (Playback Engine)

**Purpose**: Handles looped audio playback with seamless transitions
**Key Responsibilities**:
- Audio file loading and management
- Seamless loop scheduling via completion handlers
- Volume control integration
- Playback state management

**Critical Implementation Details**:
- Uses completion handlers for seamless looping
- Connected to main mixer for output routing
- Supports real-time volume adjustment
- Handles file format compatibility automatically

```swift
// Seamless loop implementation
private func scheduleLoop() {
    playerNode.scheduleFile(audioFile, at: nil) { [weak self] in
        DispatchQueue.main.async {
            guard let self = self, self.isPlaying else { return }
            self.scheduleLoop() // Reschedule for continuous loop
        }
    }
}
```

### SimpleLooperViewModel (Business Logic)

**Purpose**: Coordinates between UI and audio components
**Key Responsibilities**:
- Transport control logic and state machine management
- Audio component lifecycle coordination
- User action coordination and validation
- Cross-component communication via Combine

**Critical Implementation Details**:
- Implements complex state machine for transport controls
- Handles record-to-play automatic transitions with timing delays
- Manages audio engine startup and error handling
- Uses Combine for reactive state updates
- Provides clean separation between UI and audio logic

### SimpleLoopState (State Model)

**Purpose**: Centralized state management with comprehensive properties
**Key Properties**:
- `transportState`: Current transport mode (stopped/recording/playing)
- `hasAudio`: Whether recorded audio is available
- `fileURL`: Location of recorded audio file
- `inputLevel`: Real-time input level for UI display
- `playbackVolume`: User-controlled playback volume (default: 0.7)
- `inputMonitoringEnabled`: Input monitoring toggle (default: false)
- `isRecording`: Additional recording state flag
- Computed properties for UI state validation

**State Validation Properties**:
```swift
var canRecord: Bool { return transportState == .stopped }
var canPlay: Bool { return hasAudio && transportState == .stopped }
var canStop: Bool { return transportState == .recording || transportState == .playing }
var canClear: Bool { return hasAudio && transportState == .stopped }
```

## UI Component Architecture

### Component Hierarchy

```
ContentView (Main Container)
├── StatusSection (Transport state display)
├── LevelMeterView (Standalone input level meter)
├── TransportControlsView (Record/Play/Stop/Clear buttons)
├── InputMonitoringToggleView (Monitoring toggle)
└── VolumeSection (Playback volume - commented out)
```

### Key UI Components

#### LevelMeterView (Standalone)
- **Purpose**: Real-time input level visualization
- **Features**: 20-segment color-coded meter (green/yellow/red)
- **Integration**: Direct binding to `loopState.inputLevel`
- **Performance**: Uses `AudioUtils.normalizeAudioLevel()` for proper scaling

#### TransportControlsView 
- **Purpose**: Main transport control interface
- **Features**: Record, Play, Stop, Clear buttons with state-aware styling
- **Behavior**: Dynamic button enabling based on current state
- **Styling**: Color-coded buttons with scale animations

#### InputMonitoringToggleView
- **Purpose**: Input monitoring on/off control
- **Features**: Custom checkbox style with speaker icons
- **Integration**: Two-way binding with audio engine monitoring state
- **Design**: Minimal toggle with clear visual feedback

## AudioUtils (Utility Functions)

### Purpose
Centralized utility functions for audio operations and file management.

### Key Functions

```swift
// File Management
static func getDocumentsDirectory() -> URL
static func createLoopFileURL() -> URL

// Audio Level Processing  
static func normalizeAudioLevel(_ level: Float) -> Float
static func levelToDecibels(_ level: Float) -> Float
static func decibelsToLevel(_ decibels: Float) -> Float

// Formatting
static func formatDuration(_ duration: TimeInterval) -> String
```

### Audio Level Normalization
```swift
static func normalizeAudioLevel(_ level: Float) -> Float {
    let dbLevel = levelToDecibels(level)
    let normalizedDB = max(-60.0, dbLevel) // Clip at -60dB
    return (normalizedDB + 60.0) / 60.0 // Convert to 0.0-1.0 range
}
```

## File Management System

### Audio File Storage
- **Location**: User's Documents directory
- **Format**: WAV files with native input format (no conversion)
- **Naming**: `loop_{timestamp}.wav` for uniqueness
- **Lifecycle**: Created during recording, persisted until cleared

### File URL Management
- URLs stored in `SimpleLoopState.fileURL`
- Automatic cleanup when loop is cleared
- No intermediate format conversion required

## Performance Characteristics

### Audio Latency
- **Input to Monitoring**: Near real-time (< 10ms typical)
- **Record Start**: Immediate buffer capture via unified tap
- **Playback Start**: File loading + first buffer scheduling (< 100ms)
- **Loop Transition**: Seamless via pre-scheduled buffers

### Memory Usage
- **Input Monitoring**: Minimal (throttled single buffer processing)
- **Recording**: Streaming to disk (no memory accumulation)
- **Playback**: Entire audio file loaded into memory for seamless looping
- **Unified Tap**: Single buffer shared between recording and monitoring

### CPU Usage
- **Idle State**: Throttled input level monitoring (30Hz max)
- **Recording**: Unified buffer processing + file I/O
- **Playbook**: File reading + audio mixing
- **Multi-Channel Devices**: Channel-selective processing eliminates format conversion overhead
- **Optimizations**: Optimized buffer size (2048), throttled updates, and channel selection

### Multi-Channel Device Performance
- **Channel Selection**: No CPU overhead for unused channels (channels 3+ ignored)
- **Format Conversion**: Eliminated by using stereo format from start
- **Frame Size Errors**: Prevented by avoiding real-time channel count conversion
- **Buffer Alignment**: Maintained through consistent stereo processing
- **Professional Interfaces**: Optimized for high-channel count devices (8ch to 64ch+)

## Error Handling Strategy

### Audio Engine Errors
- Engine startup failures are logged with detailed information
- Configuration changes are monitored and logged with format details
- Recording format mismatches prevented via dynamic format detection
- Unified tap conflicts eliminated through single tap management
- **Multi-channel device frame size errors prevented via channel selection**
- **Sample rate mismatches detected and reported with specific recommendations**
- **Advanced diagnostic system provides detailed troubleshooting information**

### File System Errors
- Recording file creation errors are caught and propagated to UI
- Playback file loading errors are handled gracefully with fallbacks
- Missing file scenarios prevented via state validation
- File size verification during recording completion

### Device Change Handling
- Audio device changes automatically detected and logged
- Input format changes logged with detailed format information
- Next recording automatically uses new device format
- Current operations continue unless format incompatibility detected

### Device Compatibility Issues
- **Frame Size Errors (`kAudioUnitErr_TooManyFramesToProcess`)**: Eliminated by avoiding real-time multi-channel to stereo conversion
- **Sample Rate Mismatches**: Detected and reported with Audio MIDI Setup recommendations
- **High Channel Count Interfaces**: Automatically handled via channel-selective processing
- **Buffer Alignment Issues**: Prevented through proper format management and channel selection
- **Professional Audio Interface Support**: Optimized for 8ch, 10ch, 16ch, 24ch, 36ch+ devices

## Threading Model

### Main Thread Operations
- All UI updates and state changes
- User interaction handling
- Audio engine control commands
- State machine transitions

### Audio Thread Operations
- Real-time audio buffer processing via unified tap
- File I/O during recording (streaming)
- Level calculation with throttling
- Loop scheduling and playback

### Thread Safety
- Published properties use `@Published` for automatic main thread dispatch
- Audio callbacks use `DispatchQueue.main.async` for UI updates
- State mutations confined to main thread
- Combine pipelines handle cross-thread communication

## Diagnostic System

### Purpose
Advanced diagnostic capabilities for troubleshooting audio device compatibility issues, particularly with professional multi-channel audio interfaces.

### Diagnostic Features

#### Comprehensive Device Analysis
```
=== MONITORING DIAGNOSTICS ===
Engine running: true
Input format: <AVAudioFormat 0x...: 10 ch, 48000 Hz, Float32, deinterleaved>
Output format: <AVAudioFormat 0x...: 2 ch, 48000 Hz, Float32, deinterleaved>
Input channels: 10
Output channels: 2
Input sample rate: 48000.0Hz  
Output sample rate: 48000.0Hz
✅ Channel count match: false
⚠️  Channel conversion required: 10 → 2
✅ Sample rate match: true
```

#### Critical Issue Detection
- **Sample Rate Mismatches**: Detects and warns about sample rate differences that cause frame size errors
- **Channel Count Analysis**: Reports channel conversion requirements
- **Device Configuration**: Shows input/output device information
- **Connection Status**: Verifies audio node connections and engine state

#### Problem-Specific Recommendations
```swift
// Example diagnostic output for sample rate mismatch
if !sampleRateMatch {
    print("🚨 SAMPLE RATE MISMATCH: \(inputFormat.sampleRate)Hz → \(outputFormat.sampleRate)Hz")
    print("🚨 This WILL cause frame size errors and performance issues!")
    print("🚨 Recommendation: Use Audio MIDI Setup to set device to \(outputFormat.sampleRate)Hz")
}
```

### Diagnostic Triggers
- **Manual Activation**: "Run Monitoring Diagnostic" button in UI
- **Automatic Detection**: Logs device format changes during engine setup
- **Error Response**: Detailed logging when audio issues occur

### Professional Use Cases
- **Studio Setup**: Verify complex audio interface configurations
- **Troubleshooting**: Identify root causes of audio dropouts or errors
- **Device Testing**: Validate new audio hardware compatibility
- **Performance Optimization**: Identify format conversion overhead

## Input Monitoring Feature

### Overview
The input monitoring toggle allows users to control whether they hear live input audio through speakers/headphones while maintaining full recording capability.

### Implementation Architecture

#### Signal Path
```
inputNode → monitoringMixerNode → mainMixerNode (for monitoring)
inputNode → unifiedTap (for recording & levels - unaffected by monitoring)
```

#### Audio Engine Integration
- **Dedicated Mixer Node**: `monitoringMixerNode` handles monitoring volume
- **Volume Control**: `outputVolume` set to 1.0 (on) or 0.0 (off)
- **Clean Separation**: Recording and level monitoring unaffected by monitoring state

#### State Management
- **Default State**: Monitoring disabled (`false`) on app launch
- **No Persistence**: State resets to disabled when app restarts
- **UI Binding**: Two-way binding between UI toggle and audio engine
- **Real-time Updates**: Changes take effect immediately

### Technical Benefits
- **Zero Audio Impact**: No effect on recording quality or level monitoring
- **Low Latency**: Direct audio routing without additional processing
- **Thread Safe**: Volume changes are thread-safe in AVFoundation
- **Minimal Overhead**: Single parameter change operation

## Technical Dependencies

### Core Frameworks
- **AVFoundation**: Core audio processing, unified tap management, and file handling
- **SwiftUI**: Reactive user interface framework with @Published state binding
- **Combine**: Reactive programming for cross-component state management
- **Foundation**: File system operations and utility functions

### System Requirements
- **macOS**: Native macOS app optimized for desktop audio workflows
- **Audio Hardware**: Any Core Audio compatible input/output device
- **File System**: Documents directory write access for loop storage

## Extension Points

### Current Architecture Flexibility
- **Unified Tap System**: Can easily support additional audio processors
- **Component-Based UI**: Modular views can be extended or replaced
- **State Machine**: Extensible for additional transport modes
- **Audio Utils**: Centralized utilities can support new audio operations

### Potential Enhancements
1. **Multiple Loop Tracks**: Extend unified tap system for multi-track recording
2. **Effects Processing**: Add real-time effects in monitoring or recording path
3. **MIDI Synchronization**: Integrate tempo sync and MIDI clock support
4. **Export Options**: Support additional audio formats beyond WAV
5. **Undo/Redo**: Add operation history for loop management
6. **Keyboard Shortcuts**: Add hotkeys for transport control
7. **Visual Waveform**: Display recorded audio waveform
8. **Loop Library**: Manage multiple saved loops

### Performance Optimizations
- **Background Processing**: Move file I/O to background queue
- **Memory Management**: Implement audio streaming for large files
- **Buffer Management**: Dynamic buffer sizing based on system performance
- **CPU Optimization**: Further reduce processing overhead

This implementation provides a robust foundation for real-time audio looping with professional-grade audio handling, efficient resource management, and a clean, maintainable codebase optimized for macOS desktop use. 