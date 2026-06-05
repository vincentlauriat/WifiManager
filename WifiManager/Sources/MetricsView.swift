import SwiftUI

struct MetricsView: View {
    let metrics: NetworkMetrics

    var body: some View {
        VStack(spacing: 7) {
            MetricRow(
                icon: "antenna.radiowaves.left.and.right",
                label: "Signal",
                value: "\(metrics.rssi) dBm",
                bar: metrics.rssiBarValue,
                color: signalColor
            )
            MetricRow(
                icon: "timer",
                label: "Latence",
                value: metrics.latency.map { String(format: "%.0f ms", $0) } ?? "—",
                bar: metrics.latency.map { latencyBar($0) } ?? 0,
                color: metrics.latency.map { latencyColor($0) } ?? .secondary
            )
            MetricRow(
                icon: "speedometer",
                label: "Débit lien",
                value: String(format: "%.0f Mbps", metrics.transmitRate),
                bar: min(1.0, metrics.transmitRate / 600),
                color: .blue
            )
            if metrics.snr > 0 {
                MetricRow(
                    icon: "waveform.path.ecg",
                    label: "SNR",
                    value: "\(metrics.snr) dB",
                    bar: min(1.0, Double(metrics.snr) / 40),
                    color: metrics.snr > 25 ? .green : metrics.snr > 15 ? .orange : .red
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var signalColor: Color {
        switch metrics.rssi {
        case (-50)...:          return .green
        case (-65)...(-51):     return .green
        case (-75)...(-66):     return .orange
        default:                return .red
        }
    }

    private func latencyBar(_ ms: Double) -> Double { max(0, 1 - ms / 400) }

    private func latencyColor(_ ms: Double) -> Color {
        if ms < 30  { return .green }
        if ms < 100 { return .orange }
        return .red
    }
}

private struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let bar: Double
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 16)
                .foregroundStyle(.secondary)
                .font(.system(size: 11))

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.quaternary)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(bar))
                        .animation(.easeOut(duration: 0.3), value: bar)
                }
            }
            .frame(height: 4)

            Text(value)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.primary)
                .frame(width: 72, alignment: .trailing)
        }
        .frame(height: 18)
    }
}
