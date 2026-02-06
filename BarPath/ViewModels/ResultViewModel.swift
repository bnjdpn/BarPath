import SwiftUI

/// ViewModel for the analysis result screen, managing rep selection,
/// metric display, and export/share actions.
@Observable
@MainActor
final class ResultViewModel {

    // MARK: - Properties

    let analysis: BarPathAnalysis
    var selectedRep: Int?
    var showMetrics = true

    // MARK: - Initialization

    /// Creates a result view model for the given analysis.
    ///
    /// - Parameter analysis: The completed bar path analysis to display.
    init(analysis: BarPathAnalysis) {
        self.analysis = analysis
    }

    // MARK: - Rep Selection

    /// Selects a specific rep by its index. Pass `nil` to show all reps.
    ///
    /// - Parameter index: The zero-based rep index, or `nil` for all reps.
    func selectRep(_ index: Int?) {
        selectedRep = index
    }

    // MARK: - Computed Properties: Points

    /// The bar path points for the currently selected rep, or all points if no rep is selected.
    var displayPoints: [BarPathPoint] {
        guard let selectedRep,
              selectedRep >= 0,
              selectedRep < analysis.reps.count else {
            return analysis.points
        }

        let rep = analysis.reps[selectedRep]
        let start = rep.startIndex
        let end = min(rep.endIndex, analysis.points.count - 1)
        return Array(analysis.points[start...end])
    }

    /// The rep segment that is currently selected, if any.
    var selectedRepSegment: RepSegment? {
        guard let selectedRep,
              selectedRep >= 0,
              selectedRep < analysis.reps.count else {
            return nil
        }
        return analysis.reps[selectedRep]
    }

    // MARK: - Computed Properties: Formatted Metrics

    /// Peak velocity formatted with unit.
    var formattedPeakVelocity: String {
        String(format: "%.2f", analysis.metrics.peakVelocity)
    }

    /// Average velocity formatted with unit.
    var formattedAverageVelocity: String {
        String(format: "%.2f", analysis.metrics.averageVelocity)
    }

    /// Total vertical displacement formatted with unit.
    var formattedDisplacement: String {
        String(format: "%.3f", analysis.metrics.totalVerticalDisplacement)
    }

    /// Maximum horizontal drift formatted with unit.
    var formattedDrift: String {
        String(format: "%.3f", analysis.metrics.maxHorizontalDrift)
    }

    /// Consistency as a percentage.
    var formattedConsistency: String {
        String(format: "%.0f%%", analysis.metrics.consistency * 100)
    }

    /// Rep count as a readable string.
    var formattedRepCount: String {
        "\(analysis.metrics.repCount)"
    }

    /// Average rep duration formatted as seconds.
    var formattedAverageRepDuration: String {
        String(format: "%.1fs", analysis.metrics.averageRepDuration)
    }

    /// The analysis date formatted for display.
    var formattedDate: String {
        analysis.date.formatted(date: .abbreviated, time: .shortened)
    }

    // MARK: - Export Actions

    /// Exports the analysis video with overlay. Returns the URL of the exported file.
    func exportVideo() -> URL? {
        // In production, this would render the bar path overlay onto the video
        // and export to a temporary file for sharing.
        return analysis.videoURL
    }

    /// Creates a shareable text summary of the analysis.
    func shareAnalysis() -> String {
        let liftName = analysis.liftType.displayName
        let reps = analysis.metrics.repCount
        let peakVel = formattedPeakVelocity
        let consistency = formattedConsistency

        return String(
            format: NSLocalizedString(
                "share_analysis_summary",
                comment: "Shared analysis text summary"
            ),
            liftName,
            reps,
            peakVel,
            consistency
        )
    }
}
