import SwiftUI

// MARK: - Standalone Level Meter View
struct LevelMeterView: View {
    let level: Float
    private let meterHeight: CGFloat = 20
    private let meterWidth: CGFloat = 300
    private let segmentCount = 20
    
    var body: some View {
        VStack(spacing: 4) {
//            Text("Input Level")
//                .font(.caption)
//                .foregroundColor(.secondary)
            
            HStack(spacing: 2) {
                ForEach(0..<segmentCount, id: \.self) { index in
                    Rectangle()
                        .frame(width: (meterWidth / CGFloat(segmentCount)) - 2, height: meterHeight)
                        .foregroundColor(colorForSegment(index))
                        .opacity(shouldFillSegment(index) ? 1.0 : 0.3)
                }
            }
            .frame(height: meterHeight)
        }
    }
    
    private func shouldFillSegment(_ index: Int) -> Bool {
        let normalizedLevel = AudioUtils.normalizeAudioLevel(level)
        let fillThreshold = Float(index) / Float(segmentCount)
        return normalizedLevel >= fillThreshold
    }
    
    private func colorForSegment(_ index: Int) -> Color {
        let position = Float(index) / Float(segmentCount)
        
        if position < 0.6 {
            return .green
        } else if position < 0.8 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Standalone Input Monitoring Toggle View
struct InputMonitoringToggleView: View {
    let isMonitoringEnabled: Bool
    let onToggleMonitoring: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Toggle("Input Monitor", isOn: Binding(
                get: { isMonitoringEnabled },
                set: { _ in onToggleMonitoring() }
            ))
            .toggleStyle(CheckboxToggleStyle())
            Spacer()
        }
    }
}

// MARK: - Combined Input Monitoring View (for backward compatibility)
struct InputMonitoringView: View {
    let level: Float
    let isMonitoringEnabled: Bool
    let onToggleMonitoring: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            LevelMeterView(level: level)
            
            InputMonitoringToggleView(
                isMonitoringEnabled: isMonitoringEnabled,
                onToggleMonitoring: onToggleMonitoring
            )
        }
    }
}

// MARK: - Custom Toggle Style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: configuration.isOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .foregroundColor(configuration.isOn ? .red : .red)
                    .font(.system(size: 16))
                    .frame(width: 20, height: 16)
                    .contentShape(Rectangle())
                
                configuration.label
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Test separate components
        Text("Separate Components:")
            .font(.headline)
        
        LevelMeterView(level: 0.7)
        
        InputMonitoringToggleView(
            isMonitoringEnabled: true,
            onToggleMonitoring: {}
        )
        
        Divider()
        
        Text("Combined View (Original):")
            .font(.headline)
        
        InputMonitoringView(
            level: 0.5,
            isMonitoringEnabled: true,
            onToggleMonitoring: {}
        )
        
        InputMonitoringView(
            level: 0.8,
            isMonitoringEnabled: false,
            onToggleMonitoring: {}
        )
        
        Divider()
        
        Text("Level Meter Only:")
            .font(.headline)
        
        LevelMeterView(level: 0.1)
        LevelMeterView(level: 0.3)
        LevelMeterView(level: 0.7)
        LevelMeterView(level: 0.9)
    }
    .padding()
} 
