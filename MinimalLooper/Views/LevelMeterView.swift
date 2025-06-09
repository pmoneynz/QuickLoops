import SwiftUI

struct InputMonitoringView: View {
    let level: Float
    let isMonitoringEnabled: Bool
    let onToggleMonitoring: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            LevelMeterView(level: level)
            
            HStack(spacing: 8) {
                Toggle("Monitor Input", isOn: Binding(
                    get: { isMonitoringEnabled },
                    set: { _ in onToggleMonitoring() }
                ))
                .toggleStyle(CheckboxToggleStyle())
                
                Spacer()
            }
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                    .font(.system(size: 16))
                
                configuration.label
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct LevelMeterView: View {
    let level: Float
    private let meterHeight: CGFloat = 20
    private let meterWidth: CGFloat = 300
    private let segmentCount = 20
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Input Level")
                .font(.caption)
                .foregroundColor(.secondary)
            
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

#Preview {
    VStack(spacing: 20) {
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
        
        LevelMeterView(level: 0.0)
        LevelMeterView(level: 0.3)
        LevelMeterView(level: 0.7)
        LevelMeterView(level: 0.9)
    }
    .padding()
} 