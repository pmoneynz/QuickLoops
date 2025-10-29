# 🎵 QuickLoops

A minimal, essential audio looper application for macOS built with SwiftUI and AVFoundation. This application focuses on core looping functionality with a sophisticated unified audio processing system, providing a clean and intuitive interface for recording and playing audio loops.

## ✨ Features

### Core Functionality
- **Single Loop Recording/Playback**: Record audio input into a single loop buffer
- **Automatic Playback**: Upon stopping recording, immediately begin loop playback
- **Unlimited Recording Duration**: Record until manually stopped
- **Continuous Loop Playback**: Loops play continuously until manually stopped

### Transport Controls
- **Record Button (●)**: Start/stop recording [Return]
- **Play Button (▶)**: Start/stop playback (available when loop exists) [Space]
- **Stop Button (■)**: Stop current recording or playback [Space when recording]
- **Pitch Controls**: Adjust playback speed ±20%
  - **Pitch Up (+)**: Increase speed/pitch by 1% per click [MIDI: F2]
  - **Pitch Down (-)**: Decrease speed/pitch by 1% per click [MIDI: G2]
  - **Reset Pitch (0)**: Reset to normal speed [MIDI: A2]

### Audio Features
- **Varispeed Pitch Control**: Adjust playback speed ±20% with real-time pitch/speed control
- **Input Monitoring Toggle**: Control whether input audio is heard through speakers/headphones
- **Real-time Level Meter**: Visual feedback of incoming audio levels (first channel)
- **MIDI Integration**: Full MIDI controller support with customizable mappings
- **Keyboard Shortcuts**: Essential transport controls with tooltips
- **Loop Library**: Save and load loops with file management
- **Native Format Recording**: Records in device's native format without conversion
- **Multi-Channel Support**: Supports any channel configuration (mono, stereo, surround)
- **Variable Sample Rate Support**: Adapts to any sample rate (44.1kHz, 48kHz, 96kHz, 192kHz, etc.)
- **Dynamic Format Detection**: Automatically detects and uses device's native audio format

## 🏗️ Architecture

### Project Structure
```
QuickLoops/
├── Models/
│   └── SimpleLoopState.swift          # Comprehensive state management
├── Audio/
│   ├── SimpleAudioEngine.swift        # Unified tap audio engine
│   ├── SimpleRecorder.swift           # Native format recording
│   └── SimplePlayer.swift             # Seamless loop playback
├── Views/
│   ├── ContentView.swift              # Main application UI
│   ├── TransportControlsView.swift    # Four transport buttons
│   └── LevelMeterView.swift           # Level meter & monitoring components
├── ViewModels/
│   └── SimpleLooperViewModel.swift    # Business logic coordination
└── Utils/
    └── AudioUtils.swift               # Audio processing utilities
```

### Technical Components
- **AVAudioEngine**: Core audio processing with unified tap management
- **AVAudioInputNode**: Multi-channel microphone input with dynamic format detection
- **AVAudioMixerNode**: Separate monitoring and main mixer nodes
- **AVAudioPlayerNode**: Loop playback with seamless scheduling
- **AVAudioUnitVarispeed**: Real-time pitch/speed adjustment (±20%)
- **AVAudioFile**: Native format file recording and reading

## 🚀 Getting Started

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later
- Microphone access permission

### Building and Running
1. Open `QuickLoops.xcodeproj` in Xcode
2. Select the QuickLoops scheme
3. Build and run (⌘+R)
4. Grant microphone permission when prompted

### Usage
1. **Input Monitoring**: Use the "Input Monitor" checkbox to control live audio feedback
2. **Recording**: Click the red Record button or press Return to start recording
3. **Automatic Playback**: Recording automatically transitions to playback when stopped
4. **Manual Playback**: Use the green Play button or press Space to start/stop playback
5. **Stop**: Use the yellow Stop button or press Space (when recording) to stop
6. **Varispeed Control**: Adjust playback speed during playback using +/- buttons or MIDI notes
7. **Save/Load**: Use Cmd+S to save loops and Cmd+O to open the loop library
8. **MIDI Control**: Configure MIDI mappings in Settings for hardware controller integration

### Keyboard Shortcuts
- **Record**: Return (Enter) - Start/stop recording
- **Play**: Space - Start/stop playback (when not recording)
- **Stop**: Space - Stop recording (when recording is active)
- **Clear**: Cmd+Delete - Delete current loop
- **Save**: Cmd+S - Open save dialog for current loop
- **Load**: Cmd+O - Open loop library
- **MIDI Settings**: Access via gear icon in toolbar

## 🎛️ User Interface

The application features a clean, minimal design with:

```
┌─────────────────────────────────────┐
│            Status Display           │
│        [Recording/Playing/Stopped]  │
├─────────────────────────────────────┤
│         Input Level Meter           │
│        ████████░░░░░░░░░░░░         │
├─────────────────────────────────────┤
│          Transport Controls         │
│    [●] [▶] [■]                    │
│   Record Play Stop                 │
│                                     │
│       Pitch Controls                │
│    [-] [0] [+]                      │
│   Down Reset Up                    │
├─────────────────────────────────────┤
│        Input Monitoring             │
│    ☐ Input Monitor (OFF by default) │
└─────────────────────────────────────┘
```

### Visual Design Elements
- **Large buttons** with SF Symbols for clear visual feedback
- **Color coding**: Record (red), Play (green), Stop (yellow), Pitch (blue/purple)
- **Active button states**: Color changes and smooth animations when active
- **Varispeed display**: Shows current pitch adjustment as +/- integer (e.g., +5, -10) on reset button
- **Real-time level meter**: 20-segment horizontal bars with green/yellow/red zones
- **Input monitoring toggle**: Speaker icon with clear on/off states
- **Responsive UI**: Minimal latency with smooth state transitions

## 🔧 Technical Details

### Audio Processing Architecture
- **Unified Tap System**: Single tap handles both recording and level monitoring
- **Native Format Passthrough**: Records in device's exact format without conversion
- **Dynamic Sample Rate Support**: Automatically adapts to any device sample rate
- **Multi-Channel Recording**: Full support for mono, stereo, and surround configurations
- **Throttled Level Updates**: 30Hz update rate to prevent performance issues
- **Buffer Size**: 2048 samples for optimal performance

### Format Support
- **Sample Rates**: 44.1kHz, 48kHz, 88.2kHz, 96kHz, 176.4kHz, 192kHz, and any device-native rate
- **Bit Depths**: 16-bit, 24-bit, 32-bit float (device dependent)
- **Channels**: Mono, stereo, and multi-channel configurations
- **Format**: Linear PCM in device's native configuration

### State Management
The application uses a reactive architecture with:
- **SimpleLoopState**: Observable state object with comprehensive properties
- **SimpleLooperViewModel**: Coordinates audio components and UI using Combine
- **Unified Tap Management**: Prevents audio tap conflicts and optimizes performance

### Device Change Handling
- **Automatic Detection**: Monitors audio device configuration changes
- **Format Adaptation**: Next recording automatically uses new device format
- **Graceful Recovery**: Continues current operations when possible
- **Detailed Logging**: Comprehensive format change information

### Error Handling
- Graceful handling of audio engine failures with detailed logging
- Automatic recovery from audio device changes
- Format compatibility validation
- Thread-safe state management

## 🎚️ Varispeed Pitch Control

### Overview
Varispeed allows real-time adjustment of playback speed and pitch during loop playback. This feature uses `AVAudioUnitVarispeed` to simultaneously change both playback speed and pitch, maintaining musical relationships.

### Features
- **Range**: ±20% playback speed adjustment (0.8x to 1.2x)
- **Precision**: 1% increments per button press
- **Real-time**: Changes apply instantly during playback without interruption
- **Visual Feedback**: Current adjustment displayed as +/- integer (e.g., +5, -10, 0)
- **MIDI Support**: Full MIDI control via configurable note mappings

### Default MIDI Mappings
- **F2 (MIDI note 41)**: Pitch Up (+1%)
- **G2 (MIDI note 43)**: Pitch Down (-1%)
- **A2 (MIDI note 45)**: Reset Pitch (0%)

### Usage
1. **During Playback**: Press + button or F2 MIDI note to increase speed/pitch
2. **Speed Down**: Press - button or G2 MIDI note to decrease speed/pitch
3. **Reset**: Press the center button showing current value or A2 MIDI note to reset to normal speed
4. **Visual Feedback**: Current adjustment displayed in real-time on reset button (e.g., "+5", "-10", "0")

### Technical Implementation
- Uses `AVAudioUnitVarispeed` in the audio chain between player node and mixer
- Rate clamping ensures values stay within ±20% range
- Real-time rate changes without rescheduling playback
- State persists across playback restarts but resets when loop is cleared

## 🎧 Input Monitoring Feature

### Overview
The input monitoring toggle allows users to control whether they hear live input audio through speakers/headphones while maintaining full recording capability.

### How It Works
- **Monitor Input Checkbox**: Located below the input level meter
- **Default State**: Input monitoring is OFF when the app launches
- **Recording Behavior**: When monitoring is OFF, recording still captures input audio normally
- **Level Display**: Input level meter continues to show levels regardless of monitoring state
- **Transport Independence**: Toggle works in all transport states (stopped, recording, playing)

### Technical Implementation
Uses a dedicated monitoring mixer node in the audio signal path:

```
inputNode → monitoringMixerNode → mainMixerNode (for monitoring)
inputNode → unifiedTap (for recording & levels - unaffected by monitoring)
```

When monitoring is disabled, only the monitoring path volume is muted; recording and level monitoring continue normally through the unified tap system.

### Use Cases
- **Silent Recording**: Record without hearing input feedback
- **Feedback Prevention**: Eliminate input-to-output audio feedback loops
- **Focus Recording**: Record without audio distractions
- **Multi-Channel Recording**: Record surround audio while monitoring only stereo

## 📊 Performance Characteristics

### Audio Latency
- **Input to Monitoring**: Near real-time (< 10ms typical)
- **Record Start**: Immediate buffer capture via unified tap
- **Playback Start**: File loading + first buffer scheduling (< 100ms)
- **Loop Transition**: Seamless via pre-scheduled buffers

### Resource Usage
- **CPU Usage**: Optimized with throttled updates and unified processing
- **Memory Usage**: Streaming recording to disk, full file loading for playback
- **Multi-Channel Impact**: Linear scaling with channel count
- **High Sample Rate Support**: Automatic adaptation with proportional resource usage

## 🚫 Excluded Features

This minimal version intentionally excludes:
- Multiple loop slots
- Overdubbing/layering
- Click track/metronome
- Waveform visualization
- Audio effects (EQ, reverb, etc.)
- File import/export
- BPM detection
- Quantization
- Audio device selection UI
- Loop trimming/editing

## 🧪 Testing

### Manual Testing Checklist
- [ ] Audio engine starts without errors on various devices
- [ ] Input level meter shows real-time levels (first channel for multi-channel)
- [ ] Recording captures audio correctly in native format
- [ ] Automatic transition from recording to playback
- [ ] Loop plays continuously without dropouts
- [ ] Transport controls respond correctly in all states
- [ ] Varispeed pitch controls work correctly (±20% range)
- [ ] Pitch adjustments apply in real-time during playback
- [ ] MIDI pitch control notes (F2, G2, A2) function correctly
- [ ] Pitch reset returns to normal speed (0%)
- [ ] Input monitoring toggle works without affecting recording
- [ ] Clear function resets to ready state and varispeed
- [ ] No audio dropouts or glitches with format changes
- [ ] Memory usage remains stable during extended use
- [ ] Multi-channel devices record all channels
- [ ] High sample rate devices work correctly

### Performance Criteria
- No audio dropouts during recording/playback
- Responsive UI with minimal latency (< 50ms)
- Stable memory usage during extended use
- Graceful handling of any audio device format
- Smooth operation with multi-channel and high sample rate devices

## 🔧 Multi-Channel and Sample Rate Support

### Capabilities
- **Full Multi-Channel Support**: Records all input channels without down-mixing
- **Variable Sample Rate**: Supports any Core Audio compatible sample rate
- **Format Preservation**: No format conversion during recording
- **Device Flexibility**: Works with any macOS-compatible audio interface

### Current Limitations
- **Level Monitoring**: Only displays levels from first channel (all channels still recorded)
- **Playback Compatibility**: Playback device must support recorded format (AVFoundation handles conversion)

### Technical Architecture
The app uses dynamic format detection and native format passthrough:
- Queries device format at recording time
- Records in exact device format
- No forced format conversion
- Automatic adaptation to device changes

## 📝 License

This project is created as a demonstration of minimal audio looping functionality using SwiftUI and AVFoundation.

## 🤝 Contributing

This is a minimal implementation focused on core functionality. When contributing:

1. Maintain the minimal, single-purpose design philosophy
2. Follow SwiftUI and MVVM patterns
3. Ensure audio quality and low-latency performance
4. Test on multiple audio devices with various formats
5. Preserve the clean, uncluttered interface
6. Respect the unified tap architecture

---

**Built with SwiftUI and AVFoundation for macOS 13.0+**

## Requirements

- macOS 13.0+ (Ventura)
- Built-in microphone or external audio input device
- Audio output device (speakers/headphones)

## Installation

1. Clone the repository
2. Open `QuickLoops.xcodeproj` in Xcode
3. Build and run the project (⌘+R)

## Usage

### Basic Recording Workflow
1. **Check Input Level**: Ensure your audio device is providing input (green bars in level meter)
2. **Adjust Monitoring**: Use the "Input Monitor" checkbox to enable/disable live input monitoring (defaults to OFF)
3. **Record**: Click the Record button (●) to start recording in device's native format
4. **Stop Recording**: Click Record again to stop and automatically prepare for playback
5. **Play**: Click the Play button (▶) to hear your loop
6. **Adjust Pitch**: Use +/- buttons to adjust playback speed/pitch during playback (±20%)
7. **Reset Pitch**: Click the center button (shows current value) to reset to normal speed
8. **Stop**: Click Stop (■) to stop playback
9. **Clear**: Clear function removes the loop and resets pitch to normal

### Monitoring Controls
- **Input Level Meter**: Shows real-time input levels with 20-segment color-coded display
- **Monitor Input Toggle**: Controls whether you hear live input audio
  - ☐ **Unchecked (Default)**: Silent monitoring (input still recorded and levels shown)
  - ✓ **Checked**: Hear input audio through speakers/headphones

### Transport States
- **Press Record**: Ready to capture new loop in device's native format
- **Recording...**: Currently capturing audio input via unified tap system
- **Playing Loop**: Currently playing back recorded audio with seamless looping and varispeed control
- **Paused**: Audio recorded and ready for playback

### Varispeed Control
- **Pitch Up (+)**: Each press increases speed/pitch by 1% (up to +20%)
- **Pitch Down (-)**: Each press decreases speed/pitch by 1% (down to -20%)
- **Reset (0)**: Returns playback to normal speed (0%)
- **Display**: Current adjustment shown as +/- integer on reset button
- **MIDI**: F2 (up), G2 (down), A2 (reset) - configurable in MIDI Settings

## Architecture

### MVVM Pattern with Unified Audio Processing
- **Views**: SwiftUI interface components (ContentView, LevelMeterView, TransportControlsView)
- **ViewModels**: Business logic and state management (SimpleLooperViewModel)
- **Models**: Data structures and state objects (SimpleLoopState)
- **Audio Engine**: Unified tap management with monitoring control (SimpleAudioEngine)

### Audio Signal Flow
```
Input Device → Input Node → [Unified Tap] → Level Calc + Recording
                     ↓
              Monitoring Mixer → Main Mixer → Output Device
```

### Key Components
- **SimpleAudioEngine**: Core audio processing with unified tap and monitoring mixer
- **SimpleLoopState**: Observable state management with monitoring control
- **SimpleLooperViewModel**: Coordination between UI and audio engine
- **LevelMeterView & InputMonitoringToggleView**: Separate UI components
- **TransportControlsView**: State-aware transport buttons

## File Structure

```
QuickLoops/
├── Audio/
│   ├── SimpleAudioEngine.swift    # Unified tap engine with monitoring
│   ├── SimpleRecorder.swift       # Native format recording
│   ├── SimplePlayer.swift         # Seamless loop playback with varispeed
│   ├── LoopPreviewEngine.swift    # Loop library preview engine
│   └── MIDIManager.swift          # MIDI controller integration
├── Models/
│   ├── SimpleLoopState.swift      # State with monitoring control
│   ├── SavedLoop.swift            # Loop file metadata
│   ├── LoopLibrary.swift          # Loop collection management
│   └── MIDIConfiguration.swift    # MIDI mapping settings
├── ViewModels/
│   ├── SimpleLooperViewModel.swift # Business logic & monitoring actions
│   └── LoopLibraryViewModel.swift  # Loop library management
├── Views/
│   ├── ContentView.swift          # Main application interface
│   ├── LevelMeterView.swift       # Level meter & monitoring components
│   ├── TransportControlsView.swift # Transport buttons with tooltips
│   ├── SaveLoopView.swift         # Save loop dialog
│   ├── LoopLibraryView.swift      # Loop library browser
│   ├── LoopRowView.swift          # Individual loop list item
│   └── MIDISettingsView.swift     # MIDI configuration interface
└── Utils/
    ├── AudioUtils.swift           # Audio utility functions
    ├── LoopFileManager.swift      # Loop file management
    └── MIDIUtils.swift            # MIDI helper functions
```

## Contributing

This is a focused, minimal application optimized for professional audio workflows. When contributing:

1. Maintain the minimal, single-purpose design philosophy
2. Follow SwiftUI and MVVM patterns
3. Ensure audio quality and low-latency performance
4. Test on multiple audio devices with various formats
5. Preserve the clean, uncluttered interface
6. Respect the unified tap architecture for performance

## License

This project is available under the MIT License. 