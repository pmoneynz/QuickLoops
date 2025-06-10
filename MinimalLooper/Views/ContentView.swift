import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SimpleLooperViewModel()
    @StateObject private var midiManager = MIDIManager.shared
    @State private var showingMIDISettings = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Status Display
            statusSection
            
            // Input Level Meter (standalone)
            LevelMeterView(level: viewModel.loopState.inputLevel)
            
            // Transport Controls
            TransportControlsView(
                loopState: viewModel.loopState,
                onRecord: viewModel.recordButtonPressed,
                onPlay: viewModel.playButtonPressed,
                onStop: viewModel.stopButtonPressed,
                onClear: viewModel.clearButtonPressed
            )
            
            // Input Monitoring Toggle (standalone)
            InputMonitoringToggleView(
                isMonitoringEnabled: viewModel.loopState.inputMonitoringEnabled,
                onToggleMonitoring: viewModel.toggleInputMonitoring
            )
            
            // Diagnostic Button
            Button("Run Monitoring Diagnostic") {
                viewModel.runMonitoringDiagnostic()
            }
            .padding(.top, 10)
            .foregroundColor(.blue)
            
            // Playback Volume Control
//            volumeSection
        }
        .padding(40)
        .frame(maxWidth: 400, maxHeight: 500)
        .background(Color(NSColor.controlBackgroundColor))
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
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(spacing: 8) {
//            Text("MiniLooper")
//                .font(.title2)
//                .fontWeight(.bold)
            
            Text(statusText)
                .font(.headline)
                .foregroundColor(statusColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(statusBackgroundColor)
                .cornerRadius(12)
        }
    }
    
    private var statusText: String {
        let text: String
        switch viewModel.loopState.transportState {
        case .stopped:
            text = viewModel.loopState.hasAudio ? "Paused" : "Press Record"
        case .recording:
            text = "Recording..."
        case .playing:
            text = "Playing Loop"
        }
        return text
    }
    
    private var statusColor: Color {
        switch viewModel.loopState.transportState {
        case .stopped:
            return .primary
        case .recording:
            return .red
        case .playing:
            return .green
        }
    }
    
    private var statusBackgroundColor: Color {
        switch viewModel.loopState.transportState {
        case .stopped:
            return Color.gray.opacity(0.2)
        case .recording:
            return Color.red.opacity(0.2)
        case .playing:
            return Color.green.opacity(0.2)
        }
    }
    
    // MARK: - Volume Section
    
//    private var volumeSection: some View {
//        VStack(spacing: 8) {
//            Text("Playback Volume")
//                .font(.caption)
//                .foregroundColor(.secondary)
//            
//            HStack {
//                Image(systemName: "speaker.wave.1")
//                    .foregroundColor(.secondary)
//                
//                Slider(
//                    value: Binding(
//                        get: { viewModel.loopState.playbackVolume },
//                        set: { viewModel.setPlaybackVolume($0) }
//                    ),
//                    in: 0...1
//                )
//                .frame(width: 200)
//                
//                Image(systemName: "speaker.wave.3")
//                    .foregroundColor(.secondary)
//            }
//            
//            Text("\(Int(viewModel.loopState.playbackVolume * 100))%")
//                .font(.caption2)
//                .foregroundColor(.secondary)
//        }
//    }
    
    // MARK: - MIDI Integration
    
    private func setupMIDICallbacks() {
        midiManager.onRecord = viewModel.recordButtonPressed
        midiManager.onPlay = viewModel.playButtonPressed
        midiManager.onStop = viewModel.stopButtonPressed
        midiManager.onClear = viewModel.clearButtonPressed
    }
}

#Preview {
    ContentView()
} 
