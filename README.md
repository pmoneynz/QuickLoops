# 🎵 MiniLooper

A minimal, essential audio looper application for macOS built with SwiftUI and AVFoundation. This application focuses on core looping functionality with a sophisticated unified audio processing system, providing a clean and intuitive interface for recording and playing audio loops.

## ✨ Features

### Core Functionality
- **Single Loop Recording/Playback**: Record audio input into a single loop buffer
- **Automatic Playback**: Upon stopping recording, immediately begin loop playback
- **Unlimited Recording Duration**: Record until manually stopped
- **Continuous Loop Playback**: Loops play continuously until manually stopped

### Transport Controls
- **Record Button (●)**: Start/stop recording
- **Play Button (▶)**: Start/stop playback (available when loop exists)
- **Stop Button (■)**: Stop current recording or playback
- **Clear Button (🗑)**: Delete current loop (only when stopped)

### Audio Features
- **Input Monitoring Toggle**: Control whether input audio is heard through speakers/headphones
- **Real-time Level Meter**: Visual feedback of incoming audio levels (first channel)
- **Playback Volume Control**: Slider to control loop playback volume (currently commented out in UI)
- **Native Format Recording**: Records in device's native format without conversion
- **Multi-Channel Support**: Supports any channel configuration (mono, stereo, surround)
- **Variable Sample Rate Support**: Adapts to any sample rate (44.1kHz, 48kHz, 96kHz, 192kHz, etc.)
- **Dynamic Format Detection**: Automatically detects and uses device's native audio format

## 🏗️ Architecture

### Project Structure
```
MinimalLooper/
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
- **AVAudioFile**: Native format file recording and reading

## 🚀 Getting Started

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later
- Microphone access permission

### Building and Running
1. Open `MinimalLooper.xcodeproj` in Xcode
2. Select the MinimalLooper scheme
3. Build and run (⌘+R)
4. Grant microphone permission when prompted

### Usage
1. **Input Monitoring**: Use the "Input Monitor" checkbox to control live audio feedback
2. **Recording**: Click the red Record button to start recording
3. **Automatic Playback**: Recording automatically transitions to playback when stopped
4. **Manual Playback**: Use the green Play button to start/stop playback
5. **Stop**: Use the yellow Stop button to stop recording or playback
6. **Clear**: Use the orange Clear button to delete the current loop

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
│    [●] [▶] [■] [🗑]               │
│   Record Play Stop Clear            │
├─────────────────────────────────────┤
│        Input Monitoring             │
│    ☐ Input Monitor (OFF by default) │
└─────────────────────────────────────┘
```

### Visual Design Elements
- **Large buttons** with SF Symbols for clear visual feedback
- **Color coding**: Record (red), Play (green), Stop (yellow), Clear (orange)
- **Active button states**: Color changes and smooth animations when active
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
- MIDI integration
- Click track/metronome
- Waveform visualization
- Audio effects (EQ, reverb, etc.)
- File import/export
- Keyboard shortcuts
- Settings panel
- BPM detection
- Quantization
- Audio device selection UI
- Loop trimming/editing
- Session save/load

## 🧪 Testing

### Manual Testing Checklist
- [ ] Audio engine starts without errors on various devices
- [ ] Input level meter shows real-time levels (first channel for multi-channel)
- [ ] Recording captures audio correctly in native format
- [ ] Automatic transition from recording to playback
- [ ] Loop plays continuously without dropouts
- [ ] Transport controls respond correctly in all states
- [ ] Input monitoring toggle works without affecting recording
- [ ] Clear function resets to ready state
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
2. Open `MinimalLooper.xcodeproj` in Xcode
3. Build and run the project (⌘+R)

## Usage

### Basic Recording Workflow
1. **Check Input Level**: Ensure your audio device is providing input (green bars in level meter)
2. **Adjust Monitoring**: Use the "Input Monitor" checkbox to enable/disable live input monitoring (defaults to OFF)
3. **Record**: Click the Record button (●) to start recording in device's native format
4. **Stop Recording**: Click Record again to stop and automatically prepare for playback
5. **Play**: Click the Play button (▶) to hear your loop
6. **Stop**: Click Stop (■) to stop playback
7. **Clear**: Click Clear (🗑) to delete the current loop and start over

### Monitoring Controls
- **Input Level Meter**: Shows real-time input levels with 20-segment color-coded display
- **Monitor Input Toggle**: Controls whether you hear live input audio
  - ☐ **Unchecked (Default)**: Silent monitoring (input still recorded and levels shown)
  - ✓ **Checked**: Hear input audio through speakers/headphones

### Transport States
- **Press Record**: Ready to capture new loop in device's native format
- **Recording...**: Currently capturing audio input via unified tap system
- **Playing Loop**: Currently playing back recorded audio with seamless looping
- **Paused**: Audio recorded and ready for playback

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
MinimalLooper/
├── Audio/
│   ├── SimpleAudioEngine.swift    # Unified tap engine with monitoring
│   ├── SimpleRecorder.swift       # Native format recording
│   └── SimplePlayer.swift         # Seamless loop playback
├── Models/
│   └── SimpleLoopState.swift      # State with monitoring control
├── ViewModels/
│   └── SimpleLooperViewModel.swift # Business logic & monitoring actions
├── Views/
│   ├── ContentView.swift          # Main application interface
│   ├── LevelMeterView.swift       # Level meter & monitoring components
│   └── TransportControlsView.swift # Transport control buttons
└── Utils/
    └── AudioUtils.swift           # Audio utility functions
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