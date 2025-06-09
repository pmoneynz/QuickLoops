# 🎵 Minimal Looper

A minimal, essential audio looper application for macOS built with SwiftUI and AVFoundation. This application focuses on core looping functionality without advanced features, providing a clean and intuitive interface for recording and playing audio loops.

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
- **Input Monitoring**: Always enabled during recording
- **Real-time Level Meter**: Visual feedback of incoming audio levels
- **Playback Volume Control**: Slider to control loop playback volume
- **CD Quality Audio**: 44.1kHz/16-bit recording and playback
- **Automatic Sample Rate Conversion**: Handles different input sample rates gracefully

## 🏗️ Architecture

### Project Structure
```
MinimalLooper/
├── Models/
│   └── SimpleLoopState.swift          # Basic loop state management
├── Audio/
│   ├── SimpleAudioEngine.swift        # Core audio engine
│   ├── SimpleRecorder.swift           # Recording functionality  
│   └── SimplePlayer.swift             # Playback functionality
├── Views/
│   ├── ContentView.swift              # Main application UI
│   ├── TransportControlsView.swift    # Four transport buttons
│   └── LevelMeterView.swift           # Input level visualization
├── ViewModels/
│   └── SimpleLooperViewModel.swift    # Business logic coordination
└── Utils/
    └── AudioUtils.swift               # Helper functions for audio processing
```

### Technical Components
- **AVAudioEngine**: Core audio processing
- **AVAudioInputNode**: Microphone input
- **AVAudioMixerNode**: Audio mixing and monitoring
- **AVAudioPlayerNode**: Loop playback with automatic looping
- **AVAudioFile**: Audio file recording and reading

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
1. **Recording**: Click the red Record button to start recording
2. **Automatic Playback**: Recording automatically transitions to playback when stopped
3. **Manual Playback**: Use the green Play button to start/stop playback
4. **Stop**: Use the yellow Stop button to stop recording or playback
5. **Clear**: Use the orange Clear button to delete the current loop
6. **Volume**: Adjust playback volume with the slider

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
│         Playback Volume             │
│        ──────●─────────             │
└─────────────────────────────────────┘
```

### Visual Design Elements
- **Large buttons** with SF Symbols for clear visual feedback
- **Color coding**: Record (red), Play (green), Stop (yellow), Clear (orange)
- **Active button states**: Larger scale and bright colors when active
- **Real-time level meter**: Horizontal bars with green/yellow/red zones
- **Responsive UI**: Minimal latency with smooth animations

## 🔧 Technical Details

### Audio Processing
- **Sample Rate**: 44.1kHz (CD quality)
- **Bit Depth**: 16-bit
- **Channels**: Stereo (2 channels)
- **Format**: Linear PCM
- **Buffer Size**: 4096 samples for recording, 1024 for level monitoring

### State Management
The application uses a reactive architecture with:
- **SimpleLoopState**: Observable state object
- **SimpleLooperViewModel**: Coordinates audio components and UI
- **Combine Framework**: For reactive data binding

### Error Handling
- Graceful handling of audio engine failures
- Automatic recovery from audio interruptions
- Silent fallbacks for non-critical errors
- Console logging for debugging

## �� Excluded Features

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
- Audio device selection
- Loop trimming/editing
- Session save/load

## 🧪 Testing

### Manual Testing Checklist
- [ ] Audio engine starts without errors
- [ ] Input level meter shows real-time levels
- [ ] Recording captures audio correctly
- [ ] Automatic transition from recording to playback
- [ ] Loop plays continuously
- [ ] Transport controls respond correctly
- [ ] Volume control affects playback only
- [ ] Clear function resets to ready state
- [ ] No audio dropouts or glitches
- [ ] Memory usage remains stable

### Performance Criteria
- No audio dropouts during recording/playback
- Responsive UI with minimal latency
- Stable memory usage during extended use
- Graceful handling of different input sample rates

## 📝 License

This project is created as a demonstration of minimal audio looping functionality using SwiftUI and AVFoundation.

## 🤝 Contributing

This is a minimal implementation focused on core functionality. For feature requests or improvements, please consider the project's minimal scope and philosophy.

---

**Built with SwiftUI and AVFoundation for macOS 13.0+** 

## New Feature: Input Monitoring Toggle

### Overview
The input monitoring toggle allows users to control whether they hear live input audio through the speakers/headphones while maintaining full recording capability.

### How It Works
- **Monitor Input Checkbox**: Located below the input level meter
- **Default State**: Input monitoring is ON when the app launches
- **Recording Behavior**: When monitoring is OFF, recording still captures input audio normally
- **Level Display**: Input level meter continues to show levels regardless of monitoring state
- **Transport Independence**: Toggle works in all transport states (stopped, recording, playing)

### Use Cases
- **Silent Recording**: Record without hearing input feedback
- **Overdub Control**: Toggle monitoring during recording sessions
- **Feedback Prevention**: Eliminate input-to-output audio feedback loops
- **Focus Recording**: Record without audio distractions

### Technical Implementation
The feature uses a dedicated monitoring mixer node in the audio signal path:

```
inputNode → monitoringMixerNode → mainMixerNode (for monitoring)
inputNode → audioTap (for recording & levels - unaffected by monitoring)
```

When monitoring is disabled, only the volume of the monitoring path is muted; recording and level monitoring continue normally.

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
1. **Check Input Level**: Ensure your microphone is picking up audio (green bars in level meter)
2. **Adjust Monitoring**: Use the "Monitor Input" checkbox to enable/disable live input monitoring
3. **Record**: Click the Record button (●) or press Space to start recording
4. **Stop Recording**: Click Record again to stop and automatically prepare for playback
5. **Play**: Click the Play button (▶) to hear your loop
6. **Stop**: Click Stop (■) to stop playback
7. **Clear**: Click Clear (🗑) to delete the current loop and start over

### Monitoring Controls
- **Input Level Meter**: Shows real-time input levels with color-coded segments
- **Monitor Input Toggle**: Controls whether you hear live input audio
  - ✓ **Checked**: Hear input audio through speakers/headphones
  - ☐ **Unchecked**: Silent monitoring (input still recorded and levels still shown)

### Volume Control
- **Playback Volume Slider**: Adjusts the volume of loop playback (0-100%)
- **Volume Display**: Shows current volume percentage

### Transport States
- **Ready to Record**: No audio recorded yet, ready to capture new loop
- **Recording...**: Currently capturing audio input
- **Playing Loop**: Currently playing back recorded audio
- **Ready to Play**: Audio recorded and ready for playback

## Architecture

### MVVM Pattern
- **Views**: SwiftUI interface components
- **ViewModels**: Business logic and state management
- **Models**: Data structures and state objects
- **Audio Engine**: Core audio processing and recording

### Audio Signal Flow
```
Input Device → Input Node → Monitoring Mixer → Main Mixer → Output Device
                       ↓
                   Audio Tap (recording & levels)
```

### Key Components
- **SimpleAudioEngine**: Core audio processing with AVAudioEngine
- **SimpleLoopState**: Observable state management
- **SimpleLooperViewModel**: Coordination between UI and audio engine
- **InputMonitoringView**: Combined level meter and monitoring toggle UI
- **TransportControlsView**: Record/Play/Stop/Clear buttons

## File Structure

```
MinimalLooper/
├── Audio/
│   ├── SimpleAudioEngine.swift    # Core audio engine with monitoring
│   ├── SimpleRecorder.swift       # Audio recording functionality
│   └── SimplePlayer.swift         # Audio playback functionality
├── Models/
│   └── SimpleLoopState.swift      # App state with monitoring control
├── ViewModels/
│   └── SimpleLooperViewModel.swift # Business logic & monitoring actions
├── Views/
│   ├── ContentView.swift          # Main application interface
│   ├── LevelMeterView.swift       # Level meter & monitoring toggle
│   └── TransportControlsView.swift # Transport control buttons
└── Utils/
    └── AudioUtils.swift           # Audio utility functions
```

## Contributing

This is a focused, minimal application. When contributing:

1. Maintain the minimal, single-purpose design philosophy
2. Follow SwiftUI and MVVM patterns
3. Ensure audio quality and low-latency performance
4. Test on multiple audio devices
5. Preserve the clean, uncluttered interface

## License

This project is available under the MIT License. 