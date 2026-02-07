import SwiftUI

/// Frame-by-frame playback section for ResultView
struct FrameByFrameSection: View {
    let points: [BarPathPoint]
    @Binding var currentFrameIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                NSLocalizedString(
                    "result_frame_by_frame",
                    comment: "Frame-by-frame section header"
                )
            )
            .font(.headline)

            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { Double(currentFrameIndex) },
                        set: { currentFrameIndex = Int($0) }
                    ),
                    in: 0...Double(max(0, points.count - 1)),
                    step: 1
                )

                HStack {
                    Text(
                        String(
                            format: NSLocalizedString(
                                "result_current_frame",
                                comment: "Current frame indicator"
                            ),
                            currentFrameIndex + 1,
                            points.count
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Spacer()
                }

                if currentFrameIndex < points.count {
                    let point = points[currentFrameIndex]
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(
                                NSLocalizedString(
                                    "result_position",
                                    comment: "Position label"
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            Spacer()

                            Text(String(format: "X: %.3f, Y: %.3f", point.x, point.y))
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        if currentFrameIndex > 0 {
                            let velocities = BarPathAnalyzer.calculateVelocities(points)
                            HStack {
                                Text(
                                    NSLocalizedString(
                                        "result_velocity",
                                        comment: "Velocity label"
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)

                                Spacer()

                                Text(String(format: "%.2f u/s", velocities[currentFrameIndex]))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding(8)
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

/// Coaching tips section for ResultView
struct CoachingTipsSection: View {
    let tips: [CoachingService.Tip]

    var body: some View {
        Group {
            if !tips.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(
                        NSLocalizedString(
                            "result_coaching_tips",
                            comment: "Coaching tips section header"
                        )
                    )
                    .font(.headline)

                    VStack(spacing: 8) {
                        ForEach(tips) { tip in
                            coachingTipRow(tip)
                        }
                    }
                }
            }
        }
    }

    private func coachingTipRow(_ tip: CoachingService.Tip) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: severityIcon(tip.severity))
                .font(.body)
                .foregroundStyle(severityColor(tip.severity))
                .frame(width: 20)

            Text(tip.text)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func severityIcon(_ severity: CoachingService.Severity) -> String {
        switch severity {
        case .info: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }

    private func severityColor(_ severity: CoachingService.Severity) -> Color {
        switch severity {
        case .info: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }
}
