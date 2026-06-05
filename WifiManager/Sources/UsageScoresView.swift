import SwiftUI

struct UsageScoresView: View {
    let scores: [UsageType: NetworkQuality]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Qualité par usage")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
                spacing: 6
            ) {
                ForEach(UsageType.allCases) { usage in
                    UsageCell(usage: usage, quality: scores[usage] ?? .fair)
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
    }
}

private struct UsageCell: View {
    let usage: UsageType
    let quality: NetworkQuality

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(quality.color.opacity(0.12))
                VStack(spacing: 1) {
                    Image(systemName: usage.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(quality.color)
                    Circle()
                        .fill(quality.color)
                        .frame(width: 5, height: 5)
                }
                .padding(.vertical, 6)
            }
            Text(usage.displayName)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .help("\(usage.displayName) : \(quality.label)")
    }
}
