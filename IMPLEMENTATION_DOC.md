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
         │                       │                       │
         │              ┌─────────────────┐    ┌─────────────────┐
         │              │ SimpleLoopState │    │ SimpleRecorder  │
         │              │ (State Model)   │    │ SimplePlayer    │
         │              └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐    ┌─────────────────┐
         │              │ AudioUtils      │    │ UI Components   │
         │              │ (Utilities)     │    │ (Views)         │
         │              └─────────────────┘    └─────────────────┘
         │
         ├─── MIDI System ─────────────────────────────────────────┐
         │                                                         │
         ↓                                                         ↓
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MIDIManager   │ ←→ │ MIDI            │ ←→ │ MIDISettings    │
│   (MIDI Core)   │    │ Configuration   │    │ View            │
│                 │    │ (Data Model)    │    │ (Config UI)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐    ┌─────────────────┐
         │              │ MIDIUtils       │    │ Transport       │
         │              │ (Utilities)     │    │ Callbacks       │
         │              └─────────────────┘    └─────────────────┘
         │
         ↓
   CoreMIDI System

         ├─── Save/Load System ───────────────────────────────────┐
         │                                                         │
         ↓                                                         ↓
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ SaveLoopView    │ ←→ │ LoopLibrary     │ ←→ │ LoopFileManager │
│LoopLibraryView  │    │ ViewModel       │    │ (File Service)  │
│ (Save/Load UI)  │    │ (Business Logic)│    │ (Persistence)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐    ┌─────────────────┐
         │              │ SavedLoop       │    │ Documents/      │
         │              │ LoopLibrary     │    │ SavedLoops/     │
         │              │ (Data Models)   │    │ (File Storage)  │
         │              └─────────────────┘    └─────────────────┘
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

## MIDI Integration Architecture

### Overview
QuickLoops includes comprehensive MIDI support that allows external MIDI controllers to trigger transport actions (Record, Play, Stop, Clear) with identical visual feedback to button presses. The MIDI system is implemented as a separate service layer that integrates with the existing transport callback pattern without modifying core audio or transport logic.

### MIDI Signal Flow

```
MIDI Hardware Controller
           ↓
    CoreMIDI System (macOS)
           ↓
    MIDIManager.receiveMIDIInput()
           ↓
    [Note Mapping] → Configuration-based note-to-action mapping
           ↓
    Transport Callbacks (viewModel.recordButtonPressed, etc.)
           ↓
    Existing Transport State Machine
           ↓
    Identical Visual Feedback (UI animations, state changes)
```

### MIDI Component Architecture

#### MIDIManager (Core MIDI Service)
**Purpose**: Central MIDI system coordinator and CoreMIDI interface
**Key Responsibilities**:
- CoreMIDI client and port management
- Automatic MIDI device discovery and connection
- Real-time MIDI message processing and note event filtering
- Note-to-transport-action mapping based on configuration
- Transport callback execution with visual feedback coordination
- Device connection status monitoring
- Configuration persistence management

**Critical Implementation Details**:
```swift
class MIDIManager: ObservableObject {
    static let shared = MIDIManager()
    
    // MIDI System
    private var midiClient: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    
    // Device Management
    @Published var isConnected = false
    @Published var deviceName: String?
    
    // Configuration & Callbacks
    @Published var configuration = MIDIConfiguration()
    var onRecord: (() -> Void)?
    var onPlay: (() -> Void)?
    var onStop: (() -> Void)?
    var onClear: (() -> Void)?
    
    // Visual Feedback (synchronized with UI)
    @Published var lastTriggeredAction: TransportAction?
}
```

**Auto-Discovery System**:
- Enumerates available MIDI sources using `MIDIGetNumberOfSources()`
- Automatically connects to first available MIDI device
- Monitors device connection status changes
- Gracefully handles device disconnection with silent fallback

**MIDI Message Processing**:
- Processes only MIDI note on events (status byte 0x90)
- Ignores velocity values and note off events for simplified control
- Maps incoming note numbers to transport actions via configuration
- Executes appropriate transport callback AND sets visual feedback state

#### MIDIConfiguration (Data Model & Persistence)
**Purpose**: MIDI note mapping configuration with UserDefaults persistence
**Key Features**:
- Default note mappings for common MIDI controller layouts
- UserDefaults-based persistence across app sessions
- Helper methods for note name conversion and validation

**Default Mappings**:
```swift
struct MIDIConfiguration: Codable {
    var recordNote: UInt8 = 68    // G#4
    var playNote: UInt8 = 62      // D4  
    var stopNote: UInt8 = 64      // E4
    var clearNote: UInt8 = 65     // F4
}
```

**Persistence Implementation**:
- Automatic loading on app launch
- Real-time saving when configuration changes
- Fallback to defaults if saved configuration corrupted
- Version-compatible encoding for future updates

#### MIDISettingsView (Configuration UI)
**Purpose**: User-friendly MIDI configuration interface presented as a sheet
**Key Features**:
- Real-time device connection status display
- Visual note mapping configuration with note name display
- MIDI learning mode for easy controller setup
- Live MIDI input indication for configuration validation
- Save/Cancel workflow with proper state management

**UI Layout**:
```
┌─────────────────────────────────┐
│ MIDI Settings                   │
├─────────────────────────────────┤
│ Device Status: Connected        │
│ Device: MIDI Controller Pro     │
├─────────────────────────────────┤
│ Transport Mappings:             │
│ Record:  G#4 (68) [Learn]       │
│ Play:    D4  (62) [Learn]       │
│ Stop:    E4  (64) [Learn]       │
│ Clear:   F4  (65) [Learn]       │
├─────────────────────────────────┤
│           [Cancel] [Save]        │
└─────────────────────────────────┘
```

#### MIDIUtils (Helper Functions)
**Purpose**: MIDI-specific utility functions for note conversion and validation
**Key Functions**:
```swift
struct MIDIUtils {
    static func midiNoteToName(_ note: UInt8) -> String
    static func nameToMidiNote(_ name: String) -> UInt8?
    static func isValidMidiNote(_ note: UInt8) -> Bool
    static func noteDescription(_ note: UInt8) -> String
}
```

### MIDI Integration Pattern

#### Transport Callback Integration
The MIDI system integrates with existing transport logic through the established callback pattern:

```swift
// In ContentView.swift - MIDI callback setup
private func setupMIDICallbacks() {
    midiManager.onRecord = viewModel.recordButtonPressed
    midiManager.onPlay = viewModel.playButtonPressed  
    midiManager.onStop = viewModel.stopButtonPressed
    midiManager.onClear = viewModel.clearButtonPressed
}
```

**Integration Benefits**:
- **Zero Code Duplication**: MIDI uses exact same transport methods as UI buttons
- **Identical Behavior**: MIDI triggers produce identical state changes and visual feedback
- **Automatic Visual Sync**: UI animations automatically triggered by state changes
- **Clean Separation**: No MIDI code in existing audio or transport components

#### Visual Feedback Synchronization
MIDI-triggered actions produce identical visual feedback to button/keyboard presses:

1. **MIDI Note Received** → MIDIManager processes note
2. **Transport Callback Executed** → Calls existing transport method
3. **State Machine Updated** → Updates SimpleLoopState via existing logic
4. **UI Automatically Updates** → Existing @Published bindings trigger UI changes
5. **Visual Feedback Identical** → Same animations, colors, and state indicators

#### File Structure Integration
```
QuickLoops/
├── Audio/
│   ├── MIDIManager.swift          # Core MIDI service
│   ├── SimpleAudioEngine.swift
│   ├── SimplePlayer.swift
│   └── SimpleRecorder.swift
├── Models/
│   ├── MIDIConfiguration.swift    # MIDI data model & persistence
│   ├── SimpleLoopState.swift
│   └── (existing models)
├── Views/
│   ├── MIDISettingsView.swift     # MIDI configuration UI
│   ├── ContentView.swift          # Updated with MIDI integration
│   └── (existing views)
└── Utils/
    ├── MIDIUtils.swift           # MIDI helper functions
    ├── AudioUtils.swift
    └── (existing utils)
```

### MIDI Device Management

#### Auto-Connection System
- **Startup Behavior**: Automatically discovers and connects to first available MIDI device
- **Device Monitoring**: Continuously monitors device connection status
- **Hot-Swap Support**: Handles device disconnection/reconnection gracefully
- **Multi-Device Handling**: Focuses on single device but can be extended for multiple devices

#### Error Handling Strategy
- **Silent Fallback**: Device disconnection doesn't interrupt app operation
- **Graceful Degradation**: MIDI unavailable doesn't affect audio functionality
- **Connection Recovery**: Automatic reconnection when device becomes available
- **User Notification**: Connection status visible in settings UI

### MIDI Performance Characteristics

#### Latency
- **MIDI to Action**: Near-instantaneous processing (< 5ms typical)
- **Visual Feedback**: Identical timing to button presses
- **State Updates**: Real-time via Combine @Published properties

#### Resource Usage
- **CPU Overhead**: Minimal (MIDI processing is lightweight)
- **Memory Footprint**: Small configuration storage only
- **Background Processing**: CoreMIDI handles device communication

#### Threading Model
- **MIDI Thread**: CoreMIDI callback processes messages
- **Main Thread**: Transport callbacks and UI updates executed on main thread
- **Thread Safety**: Proper dispatching ensures UI updates on main thread

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
├── TransportControlsView (Record/Play/Stop/Clear/Save/Library buttons)
├── InputMonitoringToggleView (Monitoring toggle)
├── VolumeSection (Playback volume - commented out)
├── MIDI Integration
│   ├── MIDISettingsView (Sheet-presented configuration)
│   ├── MIDI Settings Button (Toolbar item)
│   └── MIDI Callback Setup (onAppear integration)
└── Save/Load Integration
    ├── SaveLoopView (Sheet-presented save dialog)
    ├── LoopLibraryView (Sheet-presented library browser)
    │   ├── Search/Sort Controls
    │   ├── LoopRowView (Individual loop display)
    │   └── Management Actions (Rename/Delete/Export)
    ├── Save/Library Buttons (Keyboard shortcuts Cmd+S/Cmd+O)
    └── Visual State Feedback (Save status indicators)
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

#### MIDISettingsView
- **Purpose**: MIDI configuration interface presented as a sheet
- **Features**: Device status, note mapping configuration, learning mode
- **Integration**: Two-way binding with MIDIManager.shared configuration
- **Workflow**: Save/Cancel pattern with UserDefaults persistence
- **Learning Mode**: Real-time MIDI input capture for easy controller setup
- **Design**: Clean modal interface with clear action buttons

## Utility Functions

### AudioUtils (Audio Operations)

**Purpose**: Centralized utility functions for audio operations and file management.

**Key Functions**:

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

### MIDIUtils (MIDI Operations)

**Purpose**: MIDI-specific utility functions for note conversion and validation.

**Key Functions**:

```swift
// Note Conversion
static func midiNoteToName(_ note: UInt8) -> String
static func nameToMidiNote(_ name: String) -> UInt8?

// Validation
static func isValidMidiNote(_ note: UInt8) -> Bool
static func noteDescription(_ note: UInt8) -> String

// MIDI Data Processing
static func parseMIDIPacket(_ packet: MIDIPacket) -> MIDINoteEvent?
static func isNoteOnMessage(_ statusByte: UInt8) -> Bool
```

**Note Conversion Implementation**:
```swift
static func midiNoteToName(_ note: UInt8) -> String {
    let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    let octave = Int(note / 12) - 1
    let noteIndex = Int(note % 12)
    return "\(noteNames[noteIndex])\(octave)"
}
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

### MIDI System Errors
- **Device Connection Failures**: Silent fallback with connection status updates
- **CoreMIDI Initialization Errors**: Graceful degradation without affecting audio functionality
- **Invalid MIDI Data**: Filtered and ignored (only note on events processed)
- **Device Disconnection**: Automatic status updates with no interruption to transport operations
- **Configuration Corruption**: Automatic fallback to default note mappings
- **Rapid Message Flooding**: Debounced processing prevents UI performance issues

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

### MIDI Thread Operations
- Real-time MIDI message processing via CoreMIDI callbacks
- Note event filtering and validation
- Configuration-based note-to-action mapping
- Transport callback dispatch to main thread

### Thread Safety
- Published properties use `@Published` for automatic main thread dispatch
- Audio callbacks use `DispatchQueue.main.async` for UI updates
- MIDI callbacks dispatch transport actions to main thread
- State mutations confined to main thread
- Combine pipelines handle cross-thread communication
- MIDI visual feedback updates synchronized via @Published properties

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

## Save/Load Loop Library System

### Overview
QuickLoops includes comprehensive save/load functionality that transforms it from a session-based looper into a full loop library management system. Users can save loops with custom names and metadata, browse their loop collection, and instantly load previously saved loops while maintaining the existing temporary workflow.

### Save/Load Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SaveLoopView  │ ←→ │ LoopLibrary     │ ←→ │ LoopFileManager │
│   (Save Dialog) │    │ ViewModel       │    │ (File Service)  │
│                 │    │ (Business Logic)│    │ (Persistence)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐    ┌─────────────────┐
         │              │ SavedLoop       │    │ Documents/      │
         │              │ (Data Model)    │    │ SavedLoops/     │
         │              └─────────────────┘    └─────────────────┘
         │                       │                       │
         ↓                       ↓                       ↓
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ LoopLibraryView │ ←→ │ LoopLibrary     │    │ loop_name.wav   │
│ (Browse/Manage) │    │ ObservableObject│    │ metadata.json   │
│                 │    │ (State Manager) │    │ (File Pairs)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ↓                       ↓                       ↓
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   LoopRowView   │    │ Search/Sort     │    │ Export/Import   │
│   (Individual   │    │ Filtering       │    │ Operations      │
│   Loop Display) │    │ Operations      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Implementation Details

#### Core Features Implemented

**1. SavedLoop Model**: Comprehensive data model with metadata and computed properties
- **Unique Identification**: UUID-based loop identification system
- **Rich Metadata**: Name, creation/modification dates, duration, file size
- **Computed Properties**: Formatted duration, file size, relative timestamps
- **Codable Support**: JSON serialization for metadata persistence

```swift
struct SavedLoop: Identifiable, Codable {
    let id = UUID()
    var name: String
    let originalFileName: String
    let createdAt: Date
    var modifiedAt: Date
    let duration: TimeInterval
    let fileSize: Int64
    
    // Computed properties for UI display
    var formattedDuration: String { AudioUtils.formatDuration(duration) }
    var formattedFileSize: String { ByteCountFormatter().string(fromByteCount: fileSize) }
    var formattedCreatedAt: String { DateFormatter.shortDateTime.string(from: createdAt) }
}
```

**2. LoopLibrary**: ObservableObject for managing saved loops with automatic persistence
- **Reactive State Management**: @Published properties trigger automatic UI updates
- **Lazy Loading**: Loops loaded on first access for performance
- **Automatic Persistence**: Changes automatically saved to UserDefaults
- **Memory Efficiency**: Smart caching and cleanup of loop metadata

**3. LoopFileManager**: Service layer for all file operations with robust error handling
- **Centralized File Operations**: Single source for all file system interactions
- **Error Handling**: Comprehensive LoopError enum with user-friendly messages
- **Background Threading**: File operations performed off main thread
- **Validation**: File existence, disk space, and integrity checking

**4. LoopLibraryViewModel**: Business logic for library management with search/sort/CRUD operations
- **Search Functionality**: Real-time filtering by loop name
- **Sort Options**: Multiple sort criteria (date, name, duration)
- **CRUD Operations**: Create, rename, delete with proper error handling
- **State Coordination**: Bridges UI interactions with file system operations

**5. SaveLoopView**: Modal dialog for saving loops with metadata display
- **User Input Validation**: Real-time name validation and feedback
- **Metadata Display**: Shows current loop duration and file information
- **Error Presentation**: User-friendly error messages with recovery options
- **Keyboard Support**: Enter to save, Escape to cancel

**6. LoopLibraryView**: Full-featured library browser with search, sort, and management
- **Search Interface**: Real-time search with clear visual feedback
- **Sort Controls**: Toggle between date, name, and duration sorting
- **Management Actions**: Rename, delete, export with confirmation dialogs
- **Responsive Design**: Adapts to window size with proper spacing

**7. LoopRowView**: Reusable component for displaying individual loops
- **Rich Information Display**: Name, duration, date, file size
- **Interactive Elements**: Hover effects reveal management actions
- **Context Menu**: Right-click access to rename, delete, export
- **Visual States**: Loading states, selection feedback, error indication

#### UI Integration

**Enhanced Transport Controls**:
- **Save Button**: Added to transport controls with visual feedback
- **Library Button**: Quick access to loop library browser
- **Keyboard Shortcuts**: Cmd+S (save), Cmd+O (library)
- **Visual Feedback**: Green checkmark when current loop is saved
- **State-Aware Styling**: Buttons enabled/disabled based on current state

**ContentView Integration**:
```swift
.sheet(isPresented: $viewModel.loopState.showingSaveDialog) {
    SaveLoopView(
        currentLoop: getCurrentLoopForSaving(),
        onSave: viewModel.saveCurrentLoop,
        onCancel: { viewModel.loopState.showingSaveDialog = false }
    )
}
.sheet(isPresented: $viewModel.loopState.showingLibrary) {
    LoopLibraryView(
        onLoadLoop: viewModel.loadLoop,
        onDismiss: { viewModel.loopState.showingLibrary = false }
    )
}
```

**State Management Updates**:
- **Save State Tracking**: `currentSavedLoop` property tracks save status
- **Dialog States**: Boolean flags for save/library dialog presentation
- **Computed Properties**: `canSave`, `isCurrentLoopSaved`, `canLoad` for UI logic
- **Load Integration**: Seamless integration with existing transport state machine

#### File Management

**Persistent Storage Architecture**:
```
Documents/SavedLoops/
├── loop_name_1.wav          # Audio file
├── loop_name_1.json         # Metadata file
├── loop_name_2.wav
├── loop_name_2.json
└── ...
```

**File Operations**:
- **Save Operation**: Copies temporary loop file to permanent storage with metadata
- **Load Operation**: Updates current loop state and file URL
- **Rename Operation**: Updates both audio and metadata files with validation
- **Delete Operation**: Removes both files with confirmation and cleanup
- **Export Operation**: File save dialog for user-specified locations

**Advanced File Management**:
- **Duplicate Name Handling**: Automatic name increment (e.g., "Loop (2)")
- **Orphaned File Cleanup**: Automatic detection and cleanup of orphaned files
- **Library Rebuilding**: Reconstruction of metadata from audio files when needed
- **Disk Space Validation**: Prevents save operations when insufficient space
- **File Integrity**: Validation of audio file format and metadata consistency

#### Error Handling

**Comprehensive Error System**:
```swift
enum LoopError: LocalizedError {
    case fileNotFound(String)
    case saveOperationFailed(String)
    case loadOperationFailed(String)
    case duplicateName(String)
    case invalidFormat(String)
    case insufficientSpace
    case metadataCorrupted(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "Loop '\(name)' could not be found"
        case .saveOperationFailed(let reason):
            return "Failed to save loop: \(reason)"
        // ... additional user-friendly error messages
        }
    }
}
```

**Error Recovery Strategies**:
- **Graceful Degradation**: Missing files don't crash the application
- **Automatic Recovery**: Library rebuilds from available audio files
- **User Notification**: Clear error messages with suggested actions
- **Retry Mechanisms**: Automatic retry for transient file system errors

### User Features

**Completed Functionality**:
- ✅ **Save current loop with custom name**: Modal dialog with validation
- ✅ **Browse and search saved loops**: Real-time search and filtering
- ✅ **Load previously saved loops**: One-click loading with transport integration
- ✅ **Rename and delete loops**: Context menu and confirmation dialogs
- ✅ **Export loops to custom locations**: File save dialog integration
- ✅ **Sort loops by date, name, or duration**: Multiple sort criteria
- ✅ **Visual feedback for save state**: Green checkmark when loop is saved
- ✅ **Persistent storage between sessions**: Automatic library persistence
- ✅ **Keyboard shortcuts**: Cmd+S, Cmd+O for save and library access
- ✅ **Context menus**: Right-click access to management functions

**User Experience Enhancements**:
- **Hover Effects**: Management actions revealed on hover
- **Loading States**: Visual feedback during file operations
- **Search Highlighting**: Clear indication of search matches
- **Responsive Design**: Adapts to different window sizes
- **Accessibility**: Proper focus management and keyboard navigation

### Technical Implementation

**Architecture Principles**:
- ✅ **Separation of concerns**: Clear boundaries between models, services, and views
- ✅ **Background threading**: File operations don't block UI thread
- ✅ **Reactive UI**: @Published properties enable automatic UI updates
- ✅ **Robust error handling**: Comprehensive error types and recovery
- ✅ **Memory efficiency**: Lazy loading and smart caching strategies
- ✅ **SwiftUI best practices**: Proper state management and view composition

**Performance Characteristics**:
- **Library Loading**: Lazy initialization on first access
- **Search Performance**: Real-time filtering with efficient algorithms
- **File Operations**: Background thread execution prevents UI blocking
- **Memory Usage**: Metadata-only loading until audio file needed
- **Disk Space**: Efficient storage with minimal metadata overhead

**Threading Model**:
```swift
// Background file operations
Task {
    do {
        let savedLoop = try await LoopFileManager.shared.saveLoop(
            from: tempURL, 
            name: name
        )
        await MainActor.run {
            // Update UI on main thread
            self.loopLibrary.addLoop(savedLoop)
        }
    } catch {
        await MainActor.run {
            // Handle error on main thread
            self.handleSaveError(error)
        }
    }
}
```

**Integration with Existing Architecture**:
- **Maintains Transport Logic**: No changes to existing audio engine or transport
- **Extends State Model**: Additive properties to SimpleLoopState
- **Leverages Existing Patterns**: Uses established callback and binding patterns
- **Preserves Performance**: No impact on recording or playback performance

### File System Organization

**Directory Structure**:
- **Base Location**: `~/Documents/SavedLoops/`
- **File Pairs**: Each loop consists of `.wav` audio + `.json` metadata
- **Naming Convention**: Sanitized loop names with duplicate handling
- **Backup Strategy**: Metadata includes original file references for recovery

**Metadata Schema**:
```json
{
    "id": "UUID-string",
    "name": "User Display Name",
    "originalFileName": "loop_timestamp.wav",
    "createdAt": "ISO8601-timestamp",
    "modifiedAt": "ISO8601-timestamp", 
    "duration": 123.45,
    "fileSize": 1048576
}
```

## Technical Dependencies

### Core Frameworks
- **AVFoundation**: Core audio processing, unified tap management, and file handling
- **SwiftUI**: Reactive user interface framework with @Published state binding
- **Combine**: Reactive programming for cross-component state management
- **Foundation**: File system operations, JSON encoding/decoding, and utility functions
- **CoreMIDI**: Real-time MIDI device communication and message processing
- **UniformTypeIdentifiers**: File type handling for export operations

### System Requirements
- **macOS**: Native macOS app optimized for desktop audio workflows
- **Audio Hardware**: Any Core Audio compatible input/output device
- **MIDI Hardware**: Optional - Any CoreMIDI compatible MIDI controller or device
- **File System**: Documents directory write access for loop storage, library management, and MIDI configuration persistence
- **Storage Space**: Variable based on loop length and quantity (WAV files + minimal JSON metadata)

## Extension Points

### Current Architecture Flexibility
- **Unified Tap System**: Can easily support additional audio processors
- **Component-Based UI**: Modular views can be extended or replaced
- **State Machine**: Extensible for additional transport modes
- **Audio Utils**: Centralized utilities can support new audio operations
- **MIDI System**: Modular MIDI service can be extended for additional MIDI functionality
- **Transport Callbacks**: Flexible callback pattern supports multiple input sources

### Potential Enhancements
1. **Multiple Loop Tracks**: Extend unified tap system for multi-track recording
2. **Effects Processing**: Add real-time effects in monitoring or recording path
3. **Advanced MIDI Features**: 
   - Multiple MIDI device support
   - MIDI clock synchronization and tempo control
   - MIDI CC mapping for volume and effects
   - MIDI note velocity sensitivity
   - Custom MIDI learn mode with visual feedback
   - MIDI triggering of saved loops from library
4. **Export Options**: Support additional audio formats beyond WAV (AIFF, MP3, etc.)
5. **Undo/Redo**: Add operation history for transport and library operations
6. **Additional Keyboard Shortcuts**: Add hotkeys for clear, stop, etc.
7. **Visual Waveform**: Display recorded audio waveform with playback position
8. **Loop Library Enhancements**: 
   - Tags and categories for organization
   - Advanced search with metadata filtering
   - Import/export of loop collections
   - Cloud sync capabilities
9. **MIDI Performance Mode**: Real-time loop switching via MIDI program changes
10. **MIDI Feedback**: Send MIDI messages back to controller for LED/button feedback
11. **Auto-Save Options**: Configurable automatic saving of loops
12. **Loop Templates**: Save loop settings and configurations as templates

### Performance Optimizations
- **Background Processing**: Move file I/O to background queue
- **Memory Management**: Implement audio streaming for large files
- **Buffer Management**: Dynamic buffer sizing based on system performance
- **CPU Optimization**: Further reduce processing overhead

This implementation provides a robust foundation for real-time audio looping with professional-grade audio handling, comprehensive MIDI integration, efficient resource management, and a clean, maintainable codebase optimized for macOS desktop use.

## MIDI Implementation Summary

The MIDI integration enhances QuickLoops with external controller support while maintaining the app's clean architecture and seamless user experience. Key implementation achievements:

### Integration Excellence
- **Zero Disruption**: MIDI system integrates without modifying existing audio or transport logic
- **Identical Behavior**: MIDI triggers produce identical visual feedback to manual button presses
- **Clean Separation**: MIDI functionality isolated in dedicated service layer
- **Callback Pattern**: Leverages existing transport methods for consistent state management

### User Experience
- **Plug-and-Play**: Automatic device discovery and connection
- **Visual Configuration**: User-friendly settings interface with real-time feedback
- **Persistent Settings**: Configuration automatically saved and restored
- **Learning Mode**: Easy MIDI controller setup through interactive note learning

### Technical Robustness
- **Error Resilience**: Graceful handling of device connection issues without affecting audio
- **Performance Optimized**: Minimal CPU overhead with efficient MIDI message processing
- **Thread Safe**: Proper threading model maintains UI responsiveness
- **Extensible Design**: Foundation ready for advanced MIDI features

The MIDI system transforms QuickLoops from a software-only looper into a professional performance tool that integrates seamlessly with hardware controllers, while preserving the simplicity and reliability that defines the core application experience. 