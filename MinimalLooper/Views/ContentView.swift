import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SimpleLooperViewModel()
    
    var body: some View {
        VStack(spacing: 30) {
            // Status Display
            statusSection
            
            // Input Level Meter and Monitoring Toggle
            InputMonitoringView(
                level: viewModel.loopState.inputLevel,
                isMonitoringEnabled: viewModel.loopState.inputMonitoringEnabled,
                onToggleMonitoring: viewModel.toggleInputMonitoring
            )
            
            // Transport Controls
            TransportControlsView(
                loopState: viewModel.loopState,
                onRecord: viewModel.recordButtonPressed,
                onPlay: viewModel.playButtonPressed,
                onStop: viewModel.stopButtonPressed,
                onClear: viewModel.clearButtonPressed
            )
            
            // Playback Volume Control
            volumeSection
        }
        .padding(40)
        .frame(maxWidth: 400, maxHeight: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(spacing: 8) {
            Text("Minimal Looper")
                .font(.title2)
                .fontWeight(.bold)
            
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
            text = viewModel.loopState.hasAudio ? "Ready to Play" : "Ready to Record"
        case .recording:
            text = "Recording..."
        case .playing:
            text = "Playing Loop"
        }
        
        print("🔄 [DEBUG] Status text updated: '\(text)' (transportState: \(viewModel.loopState.transportState), hasAudio: \(viewModel.loopState.hasAudio))")
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
    
    private var volumeSection: some View {
        VStack(spacing: 8) {
            Text("Playback Volume")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "speaker.wave.1")
                    .foregroundColor(.secondary)
                
                Slider(
                    value: Binding(
                        get: { viewModel.loopState.playbackVolume },
                        set: { viewModel.setPlaybackVolume($0) }
                    ),
                    in: 0...1
                )
                .frame(width: 200)
                
                Image(systemName: "speaker.wave.3")
                    .foregroundColor(.secondary)
            }
            
            Text("\(Int(viewModel.loopState.playbackVolume * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
} 