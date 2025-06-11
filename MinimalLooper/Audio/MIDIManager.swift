import Foundation
import CoreMIDI
import SwiftUI

class MIDIManager: ObservableObject {
    static let shared = MIDIManager()
    
    // MARK: - MIDI System
    private var midiClient: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    private var connectedSource: MIDIEndpointRef = 0
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var deviceName: String?
    @Published var configuration = MIDIConfiguration()
    @Published var lastTriggeredAction: TransportAction?
    @Published var availableDevices: [(name: String, source: MIDIEndpointRef)] = []
    
    // MARK: - Transport Callbacks
    var onRecord: (() -> Void)?
    var onPlay: (() -> Void)?
    var onStop: (() -> Void)?
    var onClear: (() -> Void)?
    
    // MARK: - Learning Mode
    @Published var isLearningMode = false
    @Published var learningAction: TransportAction?
    
    private init() {
        loadConfiguration()
        setupMIDI()
        refreshDeviceList()
        autoConnectFirstDevice()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    func connectToDevice(source: MIDIEndpointRef, name: String) {
        disconnectCurrentDevice()
        
        let status = MIDIPortConnectSource(inputPort, source, nil)
        if status == noErr {
            connectedSource = source
            deviceName = name
            isConnected = true
            print("✅ Connected to MIDI device: \(name)")
        } else {
            print("❌ Failed to connect to MIDI device: \(name), status: \(status)")
        }
    }
    
    func disconnectCurrentDevice() {
        if connectedSource != 0 {
            MIDIPortDisconnectSource(inputPort, connectedSource)
            connectedSource = 0
        }
        isConnected = false
        deviceName = nil
    }
    
    func refreshDeviceList() {
        availableDevices = MIDIUtils.getAvailableMIDISources()
    }
    
    func autoConnectFirstDevice() {
        refreshDeviceList()
        guard !availableDevices.isEmpty && !isConnected else { return }
        
        let firstDevice = availableDevices[0]
        connectToDevice(source: firstDevice.source, name: firstDevice.name)
    }
    
    func startLearning(for action: TransportAction) {
        isLearningMode = true
        learningAction = action
        print("🎹 Learning mode started for \(action.displayName). Press a MIDI key...")
    }
    
    func stopLearning() {
        isLearningMode = false
        learningAction = nil
        print("🎹 Learning mode stopped")
    }
    
    func saveConfiguration() {
        configuration.save()
        print("💾 MIDI configuration saved")
    }
    
    func loadConfiguration() {
        configuration = MIDIConfiguration.load()
        print("📁 MIDI configuration loaded")
    }
    
    func resetConfiguration() {
        configuration = MIDIConfiguration()
        configuration.save()
        print("🔄 MIDI configuration reset to defaults")
    }
    
    // MARK: - Private Methods
    
    private func setupMIDI() {
        // Create MIDI client
        let clientStatus = MIDIClientCreateWithBlock("QuickLoops" as CFString, &midiClient) { notification in
            // Handle MIDI system notifications
            self.handleMIDINotification(notification)
        }
        
        guard clientStatus == noErr else {
            print("❌ Failed to create MIDI client: \(clientStatus)")
            return
        }
        
        // Create input port
        let portStatus = MIDIInputPortCreateWithBlock(
            midiClient,
            "QuickLoopsInput" as CFString,
            &inputPort
        ) { [weak self] packetList, srcConnRefCon in
            self?.handleMIDIPacketList(packetList)
        }
        
        guard portStatus == noErr else {
            print("❌ Failed to create MIDI input port: \(portStatus)")
            return
        }
        
        print("✅ MIDI system initialized successfully")
    }
    
    private func handleMIDINotification(_ notification: UnsafePointer<MIDINotification>) {
        let messageType = notification.pointee.messageID
        print("🔔 MIDI notification: \(messageType)")
        
        switch messageType {
        case .msgSetupChanged, .msgObjectAdded, .msgObjectRemoved:
            DispatchQueue.main.async {
                self.refreshDeviceList()
                
                // Check if current device is still available
                if self.isConnected,
                   let currentDeviceName = self.deviceName,
                   !self.availableDevices.contains(where: { $0.name == currentDeviceName }) {
                    self.disconnectCurrentDevice()
                    self.autoConnectFirstDevice()
                }
            }
        default:
            break
        }
    }
    
    private func handleMIDIPacketList(_ packetList: UnsafePointer<MIDIPacketList>) {
        var packet = packetList.pointee.packet
        
        for _ in 0..<packetList.pointee.numPackets {
            withUnsafePointer(to: packet) { packetPtr in
                handleMIDIPacket(packetPtr)
            }
            packet = MIDIPacketNext(&packet).pointee
        }
    }
    
    private func handleMIDIPacket(_ packet: UnsafePointer<MIDIPacket>) {
        guard let midiData = MIDIUtils.parseMIDIPacket(packet) else { return }
        
        let (status, note, velocity) = midiData
        
        // Only respond to note on messages (ignore velocity)
        guard MIDIUtils.isNoteOnMessage(status: status) else { return }
        
        print("🎵 MIDI Note On: \(note) (\(MIDIUtils.midiNoteToName(note))) velocity: \(velocity)")
        
        DispatchQueue.main.async {
            self.processMIDINote(note)
        }
    }
    
    private func processMIDINote(_ note: UInt8) {
        // Handle learning mode
        if isLearningMode, let action = learningAction {
            configuration.setNote(note, for: action)
            
            // Visual feedback for learning
            lastTriggeredAction = action
            
            // Clear learning state after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.stopLearning()
                self.clearVisualFeedback()
            }
            
            print("🎯 Learned: \(action.displayName) → \(MIDIUtils.midiNoteToName(note)) (\(note))")
            return
        }
        
        // Normal operation: map note to action
        guard let action = configuration.actionForNote(note) else {
            print("🎵 Unmapped MIDI note: \(note) (\(MIDIUtils.midiNoteToName(note)))")
            return
        }
        
        // Set visual feedback
        lastTriggeredAction = action
        
        // Trigger transport action
        triggerTransportAction(action)
        
        // Clear visual feedback after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.clearVisualFeedback()
        }
        
        print("🎬 MIDI triggered: \(action.displayName)")
    }
    
    private func triggerTransportAction(_ action: TransportAction) {
        switch action {
        case .record:
            onRecord?()
        case .play:
            onPlay?()
        case .stop:
            onStop?()
        case .clear:
            onClear?()
        }
    }
    
    private func clearVisualFeedback() {
        lastTriggeredAction = nil
    }
    
    private func cleanup() {
        if connectedSource != 0 {
            MIDIPortDisconnectSource(inputPort, connectedSource)
        }
        
        if inputPort != 0 {
            MIDIPortDispose(inputPort)
        }
        
        if midiClient != 0 {
            MIDIClientDispose(midiClient)
        }
    }
} 