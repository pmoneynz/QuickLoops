import Foundation
import CoreMIDI

struct MIDIUtils {
    
    // MARK: - Note Name Conversion
    
    static func midiNoteToName(_ note: UInt8) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(note / 12) - 1
        let noteIndex = Int(note % 12)
        return "\(noteNames[noteIndex])\(octave)"
    }
    
    static func nameToMidiNote(_ name: String) -> UInt8? {
        let noteNames = ["C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11]
        
        // Parse note name and octave
        let components = name.uppercased()
        
        var noteName = ""
        var octaveString = ""
        var i = 0
        
        // Extract note name (including sharp if present)
        while i < components.count {
            let char = components[components.index(components.startIndex, offsetBy: i)]
            if char.isLetter || char == "#" {
                noteName.append(char)
                i += 1
            } else {
                break
            }
        }
        
        // Extract octave number
        octaveString = String(components.suffix(from: components.index(components.startIndex, offsetBy: i)))
        
        guard let noteValue = noteNames[noteName],
              let octave = Int(octaveString) else {
            return nil
        }
        
        let midiNote = (octave + 1) * 12 + noteValue
        return midiNote >= 0 && midiNote <= 127 ? UInt8(midiNote) : nil
    }
    
    // MARK: - MIDI Message Parsing
    
    static func parseMIDIPacket(_ packet: UnsafePointer<MIDIPacket>) -> (status: UInt8, note: UInt8, velocity: UInt8)? {
        // Check if we have at least 3 bytes for a note message
        guard packet.pointee.length >= 3 else { return nil }
        
        let data = withUnsafePointer(to: packet.pointee.data) { ptr in
            ptr.withMemoryRebound(to: UInt8.self, capacity: Int(packet.pointee.length)) { dataPtr in
                Array(UnsafeBufferPointer(start: dataPtr, count: Int(packet.pointee.length)))
            }
        }
        
        let status = data[0]
        let note = data[1]
        let velocity = data[2]
        
        return (status: status, note: note, velocity: velocity)
    }
    
    static func isNoteOnMessage(status: UInt8) -> Bool {
        return (status & 0xF0) == 0x90
    }
    
    static func isNoteOffMessage(status: UInt8) -> Bool {
        return (status & 0xF0) == 0x80
    }
    
    // MARK: - Device Discovery
    
    static func getAvailableMIDISources() -> [(name: String, source: MIDIEndpointRef)] {
        var sources: [(name: String, source: MIDIEndpointRef)] = []
        
        let sourceCount = MIDIGetNumberOfSources()
        
        for i in 0..<sourceCount {
            let source = MIDIGetSource(i)
            var nameRef: Unmanaged<CFString>?
            
            let status = MIDIObjectGetStringProperty(source, kMIDIPropertyName, &nameRef)
            
            if status == noErr, let name = nameRef?.takeRetainedValue() as String? {
                sources.append((name: name, source: source))
            }
        }
        
        return sources
    }
} 