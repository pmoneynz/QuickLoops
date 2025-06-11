# MIDI Integration Implementation Task

## Project Context

You are implementing MIDI support for **QuickLoops**, a macOS audio looping application built with SwiftUI and AVFoundation. The app has a clean MVVM architecture with sophisticated audio processing.

### Current Architecture Overview

**Key Components:**
- `SimpleLooperViewModel`: Main business logic coordinator with transport methods
- `TransportControlsView`: UI with Record/Play/Stop/Clear buttons using callback pattern
- `SimpleLoopState`: Observable state management with transport states (.stopped, .recording, .playing)
- `SimpleAudioEngine`: Unified audio processing engine
- Clean separation of concerns throughout

**Current Transport Integration:**
```swift
// In ContentView.swift
TransportControlsView(
    loopState: viewModel.loopState,
    onRecord: viewModel.recordButtonPressed,
    onPlay: viewModel.playButtonPressed,
    onStop: viewModel.stopButtonPressed,
    onClear: viewModel.clearButtonPressed
)
```

**Transport State Logic:**
- Record button: `.stopped` → `.recording` → `.stopped` (with audio)
- Play button: `.stopped` (with audio) → `.playing` → `.stopped`
- Stop button: `.recording` or `.playing` → `.stopped`
- Clear button: `.stopped` (with audio) → `.stopped` (no audio)

## Requirements

### MIDI Functionality
1. **Device Management**: Auto-detect and connect to first available MIDI device
2. **Note Mapping**: Configurable MIDI note-to-transport mappings with defaults:
   - **G#4 (68)** → Record
   - **D4 (62)** → Play
   - **E4 (64)** → Stop
   - **F4 (65)** → Clear
3. **Persistence**: Save/load MIDI mappings using UserDefaults
4. **Visual Feedback**: MIDI triggers must produce **identical** visual behavior to button/keyboard presses
5. **Settings UI**: Separate settings sheet for MIDI configuration
6. **Error Handling**: Silent fallback on device disconnection
7. **Note Events Only**: Respond to note on/off events (ignore velocity)

### Integration Requirements
- **Separation of Concerns**: MIDI as dedicated service, not integrated into existing classes
- **Callback Pattern**: Use existing transport callback functions for identical behavior
- **Single Device**: Focus on one MIDI device at a time
- **Non-Intrusive**: Zero changes to existing audio/transport logic

## Implementation Specification

### File Structure
```
QuickLoops/
├── Audio/
│   └── MIDIManager.swift          # Core MIDI service
├── Models/
│   └── MIDIConfiguration.swift    # Data model & persistence
├── Views/
│   └── MIDISettingsView.swift     # Configuration UI
└── Utils/
    └── MIDIUtils.swift           # Helper functions
```

### 1. MIDIConfiguration.swift
Create data model for MIDI mappings with persistence:

```swift
import Foundation

struct MIDIConfiguration: Codable {
    var recordNote: UInt8 = 68    // G#4
    var playNote: UInt8 = 62      // D4
    var stopNote: UInt8 = 64      // E4
    var clearNote: UInt8 = 65     // F4
    
    // Add helper methods for note name conversion
    // Add UserDefaults persistence methods
}

enum TransportAction: CaseIterable {
    case record, play, stop, clear
    
    var displayName: String { /* implementation */ }
}
```

### 2. MIDIManager.swift
Create singleton MIDI service:

```swift
import Foundation
import CoreMIDI
import SwiftUI

class MIDIManager: ObservableObject {
    static let shared = MIDIManager()
    
    // MIDI System
    private var midiClient: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    
    // Device Management
    @Published var isConnected = false
    @Published var deviceName: String?
    
    // Configuration
    @Published var configuration = MIDIConfiguration()
    
    // Transport Callbacks (set by ContentView)
    var onRecord: (() -> Void)?
    var onPlay: (() -> Void)?
    var onStop: (() -> Void)?
    var onClear: (() -> Void)?
    
    // Visual Feedback (published for UI)
    @Published var lastTriggeredAction: TransportAction?
    
    init() {
        loadConfiguration()
        setupMIDI()
        autoConnectFirstDevice()
    }
    
    // CRITICAL: Implement CoreMIDI setup with callback that processes note messages
    // CRITICAL: Auto-detect first available device
    // CRITICAL: Map incoming notes to transport actions based on configuration
    // CRITICAL: Trigger appropriate callback AND set lastTriggeredAction for visual feedback
}
```

**Key Implementation Details:**
- Use CoreMIDI's `MIDIInputPortCreateWithBlock` for note processing
- Implement auto-discovery of first available MIDI device
- Process only MIDI note on events (0x90 status byte)
- Call appropriate transport callback when mapped note received
- Set `lastTriggeredAction` for visual feedback synchronization

### 3. MIDISettingsView.swift
Create configuration UI as sheet:

```swift
import SwiftUI

struct MIDISettingsView: View {
    @ObservedObject var midiManager: MIDIManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Device status
                // Note mapping configuration for each transport action
                // Learning mode for easy mapping
                // Save/Cancel buttons
            }
            .navigationTitle("MIDI Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        midiManager.saveConfiguration()
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}
```

### 4. ContentView Integration
Modify ContentView to integrate MIDI:

```swift
struct ContentView: View {
    @StateObject private var viewModel = SimpleLooperViewModel()
    @StateObject private var midiManager = MIDIManager.shared
    @State private var showingMIDISettings = false
    
    var body: some View {
        VStack(spacing: 30) {
            // ... existing content ...
        }
        .onAppear {
            setupMIDICallbacks()
        }
        .toolbar {
            ToolbarItem {
                Button("MIDI Settings") {
                    showingMIDISettings = true
                }
            }
        }
        .sheet(isPresented: $showingMIDISettings) {
            MIDISettingsView(midiManager: midiManager)
        }
    }
    
    private func setupMIDICallbacks() {
        midiManager.onRecord = viewModel.recordButtonPressed
        midiManager.onPlay = viewModel.playButtonPressed
        midiManager.onStop = viewModel.stopButtonPressed
        midiManager.onClear = viewModel.clearButtonPressed
    }
}
```

### 5. Visual Feedback Integration
Ensure MIDI triggers produce identical visual feedback to button presses by connecting to existing animations in TransportControlsView.

**Critical Point**: Since MIDI calls the same transport methods (`viewModel.recordButtonPressed`, etc.), the existing animations triggered by state changes in `SimpleLoopState` will automatically work for MIDI inputs.

### 6. MIDIUtils.swift
Create helper utilities:

```swift
import Foundation
import CoreMIDI

struct MIDIUtils {
    static func midiNoteToName(_ note: UInt8) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(note / 12) - 1
        let noteIndex = Int(note % 12)
        return "\(noteNames[noteIndex])\(octave)"
    }
    
    static func nameToMidiNote(_ name: String) -> UInt8? {
        // Implementation for reverse conversion
    }
}
```

### 7. Project File Updates
Add new files to Xcode project build phases:
- MIDIManager.swift
- MIDIConfiguration.swift  
- MIDISettingsView.swift
- MIDIUtils.swift

## Critical Implementation Notes

### CoreMIDI Integration
1. **Setup Pattern**:
   ```swift
   private func setupMIDI() {
       var status = MIDIClientCreateWithBlock("QuickLoops" as CFString, &midiClient) { _ in }
       status = MIDIInputPortCreateWithBlock(midiClient, "Input" as CFString, &inputPort) { packetList, srcConnRefCon in
           // Process MIDI packets here
       }
   }
   ```

2. **Device Discovery**: Enumerate MIDI sources with `MIDIGetNumberOfSources()` and `MIDIGetSource()`

3. **Note Processing**: Parse MIDI packets for note on events (status byte 0x90, ignore velocity)

### State Synchronization
- MIDI manager calls existing transport methods
- Transport methods update `SimpleLoopState`
- UI automatically reflects state changes through existing bindings
- Visual feedback is inherently identical to button/keyboard presses

### Error Handling
- Silent fallback on device disconnection
- Graceful handling of MIDI system errors
- Non-blocking initialization

## Testing Requirements

1. **Functional Testing**:
   - MIDI notes trigger correct transport actions
   - Visual feedback identical to button presses
   - Settings persistence across app restarts
   - Auto-connection to first available device

2. **Integration Testing**:
   - MIDI actions respect transport state logic
   - No interference with existing audio processing  
   - Proper cleanup on app termination

3. **Edge Cases**:
   - Device disconnection during operation
   - Multiple rapid MIDI inputs
   - Invalid MIDI data handling

## Success Criteria

✅ MIDI notes trigger transport actions with identical visual behavior to buttons
✅ Settings UI allows easy note mapping configuration  
✅ Mappings persist between app sessions
✅ Auto-connects to first available MIDI device
✅ Zero impact on existing audio/transport functionality
✅ Clean separation of MIDI concerns from existing architecture

## Implementation Priority

1. **Core MIDI Integration** (MIDIManager.swift, MIDIConfiguration.swift)
2. **ContentView Integration** (callback setup)
3. **Settings UI** (MIDISettingsView.swift)
4. **Utilities and Polish** (MIDIUtils.swift, visual feedback)

Execute this implementation maintaining the existing code quality and architectural patterns. The result should feel like a natural extension of the existing application. 