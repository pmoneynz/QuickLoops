import SwiftUI

struct MIDISettingsView: View {
    @ObservedObject var midiManager: MIDIManager
    @Environment(\.dismiss) private var dismiss
    @State private var tempConfiguration: MIDIConfiguration
    @State private var showingResetConfirmation = false
    
    init(midiManager: MIDIManager) {
        self.midiManager = midiManager
        self._tempConfiguration = State(initialValue: midiManager.configuration)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom header bar
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Text("MIDI Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Save") {
                    midiManager.configuration = tempConfiguration
                    midiManager.saveConfiguration()
                    dismiss()
                }
                .fontWeight(.semibold)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(NSColor.separatorColor)),
                alignment: .bottom
            )
            
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Device Status Section
                    deviceStatusSection
                    
                    // Note Mapping Section
                    noteMappingSection
                    
                    // Reset Button
                    resetSection
                }
                .padding(24)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .frame(minWidth: 300, idealWidth: 350, maxWidth: 400,
               minHeight: 600, idealHeight: 650, maxHeight: 800)
        .onAppear {
            midiManager.refreshDeviceList()
        }
        .onDisappear {
            midiManager.stopLearning()
        }
    }
    
    // MARK: - Device Status Section
    
    private var deviceStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "cable.connector")
                    .foregroundColor(.secondary)
                Text("MIDI Device")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(midiManager.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(midiManager.isConnected ? "Connected" : "Disconnected")
                        .font(.subheadline)
                        .foregroundColor(midiManager.isConnected ? .green : .red)
                    
                    Spacer()
                }
                
                if let deviceName = midiManager.deviceName {
                    HStack {
                        Text("Device: \(deviceName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                // Device Selection
                if !midiManager.availableDevices.isEmpty {
                    devicePickingSection
                } else {
                    HStack {
                        Text("No MIDI devices found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private var devicePickingSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Available Devices:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                
                Button("Refresh") {
                    midiManager.refreshDeviceList()
                }
                .font(.caption)
            }
            
            ForEach(Array(midiManager.availableDevices.enumerated()), id: \.offset) { index, device in
                HStack {
                    Button(device.name) {
                        midiManager.connectToDevice(source: device.source, name: device.name)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(midiManager.deviceName == device.name ? .blue : .primary)
                    .fontWeight(midiManager.deviceName == device.name ? .semibold : .regular)
                    
                    Spacer()
                    
                    if midiManager.deviceName == device.name {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    // MARK: - Note Mapping Section
    
    private var noteMappingSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "music.note")
                    .foregroundColor(.secondary)
                Text("Note Mappings")
                    .font(.headline)
                Spacer()
                
                if midiManager.isLearningMode {
                    Button("Stop Learning") {
                        midiManager.stopLearning()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(TransportAction.allCases, id: \.self) { action in
                    noteMappingRow(for: action)
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private func noteMappingRow(for action: TransportAction) -> some View {
        HStack {
            // Action Icon and Name
            HStack(spacing: 8) {
                Image(systemName: action.systemImageName)
                    .foregroundColor(colorForAction(action))
                    .frame(width: 16)
                
                Text(action.displayName)
                    .frame(width: 60, alignment: .leading)
            }
            
            Spacer()
            
            // Current Note Display
            let currentNote = tempConfiguration.noteForAction(action)
            Text(MIDIUtils.midiNoteToName(currentNote))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
            
            Text("(\(currentNote))")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 35, alignment: .leading)
            
            // Learn Button
            Button(midiManager.isLearningMode && midiManager.learningAction == action ? "Listening..." : "Learn") {
                if midiManager.isLearningMode && midiManager.learningAction == action {
                    midiManager.stopLearning()
                } else {
                    midiManager.startLearning(for: action)
                }
            }
            .buttonStyle(BorderedButtonStyle())
            .controlSize(.small)
            .foregroundColor(midiManager.isLearningMode && midiManager.learningAction == action ? .red : .blue)
            .disabled(!midiManager.isConnected)
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(midiManager.lastTriggeredAction == action ? Color.blue.opacity(0.2) : Color.clear)
        )
        .onChange(of: midiManager.configuration) { _, newConfig in
            tempConfiguration = newConfig
        }
    }
    
    private func colorForAction(_ action: TransportAction) -> Color {
        switch action {
        case .record: return .red
        case .play: return .green
        case .stop: return .yellow
        case .clear: return .orange
        case .pitchUp: return .blue
        case .pitchDown: return .blue
        case .pitchReset: return .purple
        }
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        VStack(spacing: 8) {
            Button("Reset to Defaults") {
                showingResetConfirmation = true
            }
            .foregroundColor(.red)
        }
        .alert("Reset MIDI Configuration", isPresented: $showingResetConfirmation) {
            Button("Reset", role: .destructive) {
                tempConfiguration = MIDIConfiguration()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset all MIDI note mappings to their default values.")
        }
    }
}

#Preview {
    MIDISettingsView(midiManager: MIDIManager.shared)
} 
