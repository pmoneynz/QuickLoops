import SwiftUI

struct TransportControlsView: View {
    @ObservedObject var loopState: SimpleLoopState
    
    let onRecord: () -> Void
    let onPlay: () -> Void
    let onStop: () -> Void
    let onClear: () -> Void
    let onPitchUp: () -> Void
    let onPitchDown: () -> Void
    let onPitchReset: () -> Void
    
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
            }
            
            // Pitch Control Buttons
            HStack(spacing: 20) {
                // Pitch Down Button
                Button(action: onPitchDown) {
                    Image(systemName: "minus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: buttonSize * 0.75, height: buttonSize * 0.75)
                        .background(pitchDownButtonColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!pitchDownButtonEnabled)
                .animation(.easeInOut(duration: 0.2), value: loopState.varispeedRate)
                .help("Pitch Down [MIDI: G2]")
                
                // Pitch Reset Button
                Button(action: onPitchReset) {
                    Text(varispeedDisplayText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 50)
                        .foregroundColor(.white)
                        .frame(width: buttonSize * 0.75, height: buttonSize * 0.75)
                        .background(pitchResetButtonColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!pitchResetButtonEnabled)
                .animation(.easeInOut(duration: 0.2), value: loopState.varispeedRate)
                .help("Reset Pitch [MIDI: A2]")
                
                // Pitch Up Button
                Button(action: onPitchUp) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: buttonSize * 0.75, height: buttonSize * 0.75)
                        .background(pitchUpButtonColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!pitchUpButtonEnabled)
                .animation(.easeInOut(duration: 0.2), value: loopState.varispeedRate)
                .help("Pitch Up [MIDI: F2]")
                
            }
            .padding(.top, 8)
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
    
    private var pitchUpButtonEnabled: Bool {
        loopState.hasAudio && loopState.varispeedRate < 1.2
    }
    
    private var pitchDownButtonEnabled: Bool {
        loopState.hasAudio && loopState.varispeedRate > 0.8
    }
    
    private var pitchResetButtonEnabled: Bool {
        loopState.hasAudio && abs(loopState.varispeedRate - 1.0) > 0.001
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
    
    private var pitchUpButtonColor: Color {
        if !pitchUpButtonEnabled {
            return .gray
        }
        return loopState.varispeedRate >= 1.2 ? .blue.opacity(0.6) : .blue
    }
    
    private var pitchDownButtonColor: Color {
        if !pitchDownButtonEnabled {
            return .gray
        }
        return loopState.varispeedRate <= 0.8 ? .blue.opacity(0.6) : .blue
    }
    
    private var pitchResetButtonColor: Color {
        if !pitchResetButtonEnabled {
            return .gray
        }
        return .purple
    }
    
    private var varispeedDisplayText: String {
        let percentage = loopState.varispeedPercentage
        if abs(percentage) < 0.5 {
            return "0"
        }
        return String(format: "%+.0f", percentage)
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
            onClear: {},
            onPitchUp: {},
            onPitchDown: {},
            onPitchReset: {}
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
            onClear: {},
            onPitchUp: {},
            onPitchDown: {},
            onPitchReset: {}
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
            onClear: {},
            onPitchUp: {},
            onPitchDown: {},
            onPitchReset: {}
        )
    }
    .padding()
} 
