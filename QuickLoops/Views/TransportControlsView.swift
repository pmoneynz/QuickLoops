import SwiftUI

struct TransportControlsView: View {
    @ObservedObject var loopState: SimpleLoopState
    
    let onRecord: () -> Void
    let onPlay: () -> Void
    let onStop: () -> Void
    let onClear: () -> Void
    
    private let buttonSize: CGFloat = 60
    
    var body: some View {
        VStack(spacing: 16) {
            
            HStack(spacing: 20) {
                // Record Button
                Button(action: onRecord) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: buttonSize, height: buttonSize)
                        .background(recordButtonColor)
                        .clipShape(Circle())
                        .scaleEffect(recordButtonScale)
                }
                .buttonStyle(.plain)
                .disabled(!recordButtonEnabled)
                .animation(.easeInOut(duration: 0.2), value: loopState.transportState)
                .keyboardShortcut(.return, modifiers: [])
                .help("Record [Return]")
                
                // Play Button
                Button(action: onPlay) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: buttonSize, height: buttonSize)
                        .background(playButtonColor)
                        .clipShape(Circle())
                        .scaleEffect(playButtonScale)
                }
                .buttonStyle(.plain)
                .disabled(!playButtonEnabled)
                .animation(.easeInOut(duration: 0.2), value: loopState.transportState)
                .keyboardShortcut(playButtonKeyboardShortcut, modifiers: [])
                .help("Play [Space]")
                
                // Stop Button
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: buttonSize, height: buttonSize)
                        .background(stopButtonColor)
                        .clipShape(Circle())
                        .scaleEffect(stopButtonScale)
                }
                .buttonStyle(.plain)
                .disabled(!stopButtonEnabled)
                .animation(.easeInOut(duration: 0.2), value: loopState.transportState)
                .keyboardShortcut(stopButtonKeyboardShortcut, modifiers: [])
                .help("Stop [Space]")
                
                // Clear Button
                Button(action: onClear) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: buttonSize, height: buttonSize)
                        .background(clearButtonColor)
                        .clipShape(Circle())
                        .scaleEffect(clearButtonScale)
                }
                .buttonStyle(.plain)
                .disabled(!clearButtonEnabled)
                .animation(.easeInOut(duration: 0.2), value: loopState.transportState)
                .keyboardShortcut(.delete, modifiers: [.command])
                .help("Clear [Cmd+Delete]")
            }
        }
    }
    
    // MARK: - Button States
    
    private var recordButtonEnabled: Bool {
        loopState.canRecord || loopState.transportState == .recording
    }
    
    private var playButtonEnabled: Bool {
        loopState.canPlay || loopState.transportState == .playing
    }
    
    private var stopButtonEnabled: Bool {
        loopState.canStop
    }
    
    private var clearButtonEnabled: Bool {
        loopState.canClear
    }
    
    // MARK: - Button Icons
    
    private var recordButtonIcon: String {
        loopState.transportState == .recording ? "stop.circle.fill" : "record.circle.fill"
    }
    
    private var playButtonIcon: String {
        loopState.transportState == .playing ? "pause.circle.fill" : "play.circle.fill"
    }
    
    // MARK: - Button Colors
    
    private var recordButtonColor: Color {
        if !recordButtonEnabled {
            return .gray
        }
        return loopState.transportState == .recording ? .red.opacity(0.8) : .red
    }
    
    private var playButtonColor: Color {
        if !playButtonEnabled {
            return .gray
        }
        return loopState.transportState == .playing ? .green.opacity(0.8) : .green
    }
    
    private var stopButtonColor: Color {
        stopButtonEnabled ? .yellow : .gray
    }
    
    private var clearButtonColor: Color {
        clearButtonEnabled ? .orange : .gray
    }
    
    // MARK: - Button Scales
    
    private var recordButtonScale: CGFloat {
        loopState.transportState == .recording ? 1.0 : 1.0
    }
    
    private var playButtonScale: CGFloat {
        loopState.transportState == .playing ? 1.0 : 1.0
    }
    
    private var stopButtonScale: CGFloat {
        stopButtonEnabled ? 1.0 : 1.0
    }
    
    private var clearButtonScale: CGFloat {
        clearButtonEnabled ? 1.0 : 1.0
    }
    
    // MARK: - Keyboard Shortcuts
    
    private var playButtonKeyboardShortcut: KeyEquivalent {
        // Only use space for play when not recording
        loopState.transportState != .recording ? .space : KeyEquivalent("p")
    }
    
    private var stopButtonKeyboardShortcut: KeyEquivalent {
        // Use space for stop when recording, otherwise use a different key
        loopState.transportState == .recording ? .space : KeyEquivalent(".")
    }
}

#Preview {
    VStack(spacing: 40) {
        // Stopped state with no audio
        TransportControlsView(
            loopState: {
                let state = SimpleLoopState()
                state.transportState = .stopped
                state.hasAudio = false
                return state
            }(),
            onRecord: {},
            onPlay: {},
            onStop: {},
            onClear: {}
        )
        
        // Recording state
        TransportControlsView(
            loopState: {
                let state = SimpleLoopState()
                state.transportState = .recording
                state.hasAudio = false
                return state
            }(),
            onRecord: {},
            onPlay: {},
            onStop: {},
            onClear: {}
        )
        
        // Playing state
        TransportControlsView(
            loopState: {
                let state = SimpleLoopState()
                state.transportState = .playing
                state.hasAudio = true
                return state
            }(),
            onRecord: {},
            onPlay: {},
            onStop: {},
            onClear: {}
        )
    }
    .padding()
} 
