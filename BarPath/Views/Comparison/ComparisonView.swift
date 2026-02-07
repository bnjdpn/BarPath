import SwiftUI

/// Displays a side-by-side comparison of two bar path analyses,
/// showing overlaid paths and metric differences.
struct ComparisonView: View {

    // MARK: - Properties

    @State private var viewModel: ComparisonViewModel

    // MARK: - Initialization

    init(analysisA: BarPathAnalysis, analysisB: BarPathAnalysis) {
        _viewModel = State(initialValue: ComparisonViewModel(analysisA: analysisA, analysisB: analysisB))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                pathOverlaySection
                metricsComparisonSection
            }
            .padding()
        }
        .navigationTitle(
            NSLocalizedString(
                "comparison_title",
                comment: "Comparison view title"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Path Overlay Section

    private var pathOverlaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                NSLocalizedString(
                    "comparison_overlaid_paths",
                    comment: "Overlaid paths section header"
                )
            )
            .font(.headline)

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.black)
                    .frame(height: 400)

                ComparisonOverlayView(
                    pointsA: viewModel.normalizedPointsA,
                    pointsB: viewModel.normalizedPointsB
                )
            }

            HStack(spacing: 16) {
                Label {
                    Text(
                        NSLocalizedString(
                            "comparison_analysis_a",
                            comment: "Analysis A label"
                        )
                    )
                } icon: {
                    Circle()
                        .fill(.blue)
                        .frame(width: 12, height: 12)
                }
                .font(.caption)

                Label {
                    Text(
                        NSLocalizedString(
                            "comparison_analysis_b",
                            comment: "Analysis B label"
                        )
                    )
                } icon: {
                    Circle()
                        .fill(.orange)
                        .frame(width: 12, height: 12)
                }
                .font(.caption)
            }
        }
    }

    // MARK: - Metrics Comparison Section

    private var metricsComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                NSLocalizedString(
                    "comparison_metrics",
                    comment: "Metrics comparison section header"
                )
            )
            .font(.headline)

            VStack(spacing: 0) {
                comparisonHeader

                Divider()

                comparisonRow(
                    metric: NSLocalizedString("metric_peak_velocity", comment: "Peak velocity"),
                    valueA: String(format: "%.2f", viewModel.analysisA.metrics.peakVelocity),
                    valueB: String(format: "%.2f", viewModel.analysisB.metrics.peakVelocity),
                    difference: viewModel.peakVelocityDifference
                )

                Divider()

                comparisonRow(
                    metric: NSLocalizedString("metric_avg_velocity", comment: "Average velocity"),
                    valueA: String(format: "%.2f", viewModel.analysisA.metrics.averageVelocity),
                    valueB: String(format: "%.2f", viewModel.analysisB.metrics.averageVelocity),
                    difference: viewModel.averageVelocityDifference
                )

                Divider()

                comparisonRow(
                    metric: NSLocalizedString("metric_displacement", comment: "Displacement"),
                    valueA: String(format: "%.3f", viewModel.analysisA.metrics.totalVerticalDisplacement),
                    valueB: String(format: "%.3f", viewModel.analysisB.metrics.totalVerticalDisplacement),
                    difference: viewModel.displacementDifference
                )

                Divider()

                comparisonRow(
                    metric: NSLocalizedString("metric_drift", comment: "Drift"),
                    valueA: String(format: "%.3f", viewModel.analysisA.metrics.maxHorizontalDrift),
                    valueB: String(format: "%.3f", viewModel.analysisB.metrics.maxHorizontalDrift),
                    difference: viewModel.driftDifference
                )

                Divider()

                comparisonRow(
                    metric: NSLocalizedString("metric_consistency", comment: "Consistency"),
                    valueA: String(format: "%.0f%%", viewModel.analysisA.metrics.consistency * 100),
                    valueB: String(format: "%.0f%%", viewModel.analysisB.metrics.consistency * 100),
                    difference: viewModel.consistencyDifference
                )

                Divider()

                comparisonRow(
                    metric: NSLocalizedString("metric_rep_count", comment: "Rep count"),
                    valueA: "\(viewModel.analysisA.metrics.repCount)",
                    valueB: "\(viewModel.analysisB.metrics.repCount)",
                    difference: viewModel.repCountDifference
                )
            }
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Comparison Table Components

    private var comparisonHeader: some View {
        HStack {
            Text(
                NSLocalizedString(
                    "comparison_metric",
                    comment: "Metric column header"
                )
            )
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(
                NSLocalizedString(
                    "comparison_analysis_a",
                    comment: "Analysis A column header"
                )
            )
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.blue)
            .frame(width: 70, alignment: .trailing)

            Text(
                NSLocalizedString(
                    "comparison_analysis_b",
                    comment: "Analysis B column header"
                )
            )
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.orange)
            .frame(width: 70, alignment: .trailing)

            Text(
                NSLocalizedString(
                    "comparison_difference",
                    comment: "Difference column header"
                )
            )
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func comparisonRow(
        metric: String,
        valueA: String,
        valueB: String,
        difference: String
    ) -> some View {
        HStack {
            Text(metric)
                .font(.caption)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(valueA)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.blue)
                .frame(width: 70, alignment: .trailing)

            Text(valueB)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.orange)
                .frame(width: 70, alignment: .trailing)

            Text(difference)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(differenceColor(difference))
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func differenceColor(_ difference: String) -> Color {
        if difference == "—" {
            return .secondary
        } else if difference.hasPrefix("+") {
            return .green
        } else if difference.hasPrefix("-") {
            return .red
        } else {
            return .secondary
        }
    }
}

// MARK: - Comparison Overlay View

/// Canvas view that draws both bar paths overlaid on the same coordinate system.
private struct ComparisonOverlayView: View {
    let pointsA: [BarPathPoint]
    let pointsB: [BarPathPoint]

    var body: some View {
        Canvas { context, size in
            drawPath(context: context, size: size, points: pointsA, color: .blue)
            drawPath(context: context, size: size, points: pointsB, color: .orange)
        }
        .allowsHitTesting(false)
    }

    private func drawPath(
        context: GraphicsContext,
        size: CGSize,
        points: [BarPathPoint],
        color: Color
    ) {
        guard points.count >= 2 else { return }

        for i in 1..<points.count {
            let from = scaledPoint(points[i - 1], in: size)
            let to = scaledPoint(points[i], in: size)

            var path = Path()
            path.move(to: from)
            path.addLine(to: to)

            context.stroke(
                path,
                with: .color(color),
                lineWidth: 3
            )
        }

        for point in points {
            let center = scaledPoint(point, in: size)
            let dotRadius = CGFloat(3)

            let dotRect = CGRect(
                x: center.x - dotRadius,
                y: center.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            )

            context.fill(
                Path(ellipseIn: dotRect),
                with: .color(color.opacity(0.8))
            )
        }
    }

    private func scaledPoint(_ point: BarPathPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: point.x * size.width,
            y: point.y * size.height
        )
    }
}
