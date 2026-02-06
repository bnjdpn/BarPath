import AVKit
import SwiftUI

/// Displays the completed analysis result with a video player, bar path overlay,
/// metrics panel, and rep selector.
struct ResultView: View {

    // MARK: - Properties

    @State private var viewModel: ResultViewModel
    @State private var isPlaying = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(analysis: BarPathAnalysis) {
        _viewModel = State(initialValue: ResultViewModel(analysis: analysis))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                videoSection
                repSelector
                metricsSection
            }
            .padding()
        }
        .navigationTitle(viewModel.analysis.liftType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                shareButton
            }
        }
    }

    // MARK: - Video Section

    private var videoSection: some View {
        ZStack {
            // Video player or placeholder
            if let videoURL = viewModel.analysis.videoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        BarPathOverlayView(
                            points: viewModel.displayPoints,
                            allPoints: viewModel.analysis.points,
                            reps: viewModel.analysis.reps,
                            selectedRep: viewModel.selectedRep,
                            colorMode: .velocity
                        )
                    }
            } else {
                // No video available; show the overlay on a dark background.
                RoundedRectangle(cornerRadius: 16)
                    .fill(.black)
                    .frame(height: 300)
                    .overlay {
                        BarPathOverlayView(
                            points: viewModel.displayPoints,
                            allPoints: viewModel.analysis.points,
                            reps: viewModel.analysis.reps,
                            selectedRep: viewModel.selectedRep,
                            colorMode: .velocity
                        )
                    }
            }
        }
    }

    // MARK: - Rep Selector

    private var repSelector: some View {
        RepSelector(
            repCount: viewModel.analysis.reps.count,
            selectedRep: Binding(
                get: { viewModel.selectedRep },
                set: { viewModel.selectRep($0) }
            )
        )
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                NSLocalizedString(
                    "result_metrics_header",
                    comment: "Metrics section header"
                )
            )
            .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {
                MetricCard(
                    icon: "gauge.open.with.lines.needle.33percent.and.arrowtriangle",
                    title: NSLocalizedString(
                        "metric_peak_velocity",
                        comment: "Peak velocity metric"
                    ),
                    value: viewModel.formattedPeakVelocity,
                    unit: NSLocalizedString("unit_velocity", comment: "Velocity unit")
                )

                MetricCard(
                    icon: "speedometer",
                    title: NSLocalizedString(
                        "metric_avg_velocity",
                        comment: "Average velocity metric"
                    ),
                    value: viewModel.formattedAverageVelocity,
                    unit: NSLocalizedString("unit_velocity", comment: "Velocity unit")
                )

                MetricCard(
                    icon: "arrow.up.and.down",
                    title: NSLocalizedString(
                        "metric_displacement",
                        comment: "Displacement metric"
                    ),
                    value: viewModel.formattedDisplacement,
                    unit: NSLocalizedString("unit_normalized", comment: "Normalized unit")
                )

                MetricCard(
                    icon: "arrow.left.and.right",
                    title: NSLocalizedString(
                        "metric_drift",
                        comment: "Horizontal drift metric"
                    ),
                    value: viewModel.formattedDrift,
                    unit: NSLocalizedString("unit_normalized", comment: "Normalized unit")
                )

                MetricCard(
                    icon: "checkmark.seal",
                    title: NSLocalizedString(
                        "metric_consistency",
                        comment: "Consistency metric"
                    ),
                    value: viewModel.formattedConsistency
                )

                MetricCard(
                    icon: "repeat",
                    title: NSLocalizedString(
                        "metric_rep_count",
                        comment: "Rep count metric"
                    ),
                    value: viewModel.formattedRepCount,
                    unit: NSLocalizedString("unit_reps", comment: "Reps unit")
                )
            }
        }
    }

    // MARK: - Share Button

    private var shareButton: some View {
        ShareLink(
            item: viewModel.shareAnalysis(),
            subject: Text(viewModel.analysis.liftType.displayName),
            message: Text(viewModel.shareAnalysis())
        ) {
            Image(systemName: "square.and.arrow.up")
        }
    }
}
