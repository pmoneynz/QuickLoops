import SwiftUI

struct TransportControlsView: View {
    @ObservedObject var loopState: SimpleLoopState
    
    let onRecord: () -> Void
    let onPlay: () -> Void
    let onStop: () -> Void
    let onClear: () -> Void
    let onSave: () -> Void
    let onShowLibrary: () -> Void
    
    private let buttonSize: CGFloat = 60
    
    var body: some View {
        VStack(spacing: 16) {
//            Text("Transport Controls")
//                .font(.caption)
//                .foregroundColor(.secondary)
            
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
                .keyboardShortcut(.space, modifiers: [])
                
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
                .keyboardShortcut(".", modifiers: [.command])
                
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
            }
            
            // Save/Load buttons row
            HStack(spacing: 20) {
                // Save Button
                Button(action: onSave) {
                    HStack(spacing: 6) {
                        Image(systemName: loopState.isCurrentLoopSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                            .font(.system(size: 16, weight: .medium))
                        Text(loopState.isCurrentLoopSaved ? "Saved" : "Save")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(saveButtonColor)
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
                .disabled(!saveButtonEnabled)
                .keyboardShortcut("s", modifiers: [.command])
                
                // Library Button
                Button(action: onShowLibrary) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Library")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(libraryButtonColor)
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
                .disabled(!libraryButtonEnabled)
                .keyboardShortcut("o", modifiers: [.command])
            }
            
            // Button labels
//            HStack(spacing: 20) {
//                Text("Record")
//                    .frame(width: buttonSize)
//                    .font(.caption)
//                    .foregroundColor(recordButtonEnabled ? .primary : .secondary)
//                
//                Text("Play")
//                    .frame(width: buttonSize)
//                    .font(.caption)
//                    .foregroundColor(playButtonEnabled ? .primary : .secondary)
//                
//                Text("Stop")
//                    .frame(width: buttonSize)
//                    .font(.caption)
//                    .foregroundColor(stopButtonEnabled ? .primary : .secondary)
//                
//                Text("Clear")
//                    .frame(width: buttonSize)
//                    .font(.caption)
//                    .foregroundColor(clearButtonEnabled ? .primary : .secondary)
//            }
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
    
    private var saveButtonEnabled: Bool {
        loopState.canSave
    }
    
    private var libraryButtonEnabled: Bool {
        loopState.canLoad
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
    
    private var saveButtonColor: Color {
        if loopState.isCurrentLoopSaved {
            return .green
        }
        return saveButtonEnabled ? .blue : .gray
    }
    
    private var libraryButtonColor: Color {
        libraryButtonEnabled ? .purple : .gray
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
            onSave: {},
            onShowLibrary: {}
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
            onSave: {},
            onShowLibrary: {}
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
            onSave: {},
            onShowLibrary: {}
        )
    }
    .padding()
} 
