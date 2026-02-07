import Foundation

/// ViewModel for comparing two bar path analyses side-by-side.
@Observable
@MainActor
final class ComparisonViewModel {

    // MARK: - Properties

    let analysisA: BarPathAnalysis
    let analysisB: BarPathAnalysis

    var normalizedPointsA: [BarPathPoint] = []
    var normalizedPointsB: [BarPathPoint] = []

    // MARK: - Initialization

    /// Creates a comparison view model for two analyses.
    ///
    /// - Parameters:
    ///   - analysisA: The first analysis to compare.
    ///   - analysisB: The second analysis to compare.
    init(analysisA: BarPathAnalysis, analysisB: BarPathAnalysis) {
        self.analysisA = analysisA
        self.analysisB = analysisB
        self.normalizePoints()
    }

    // MARK: - Normalization

    /// Normalizes both analyses' points to the same vertical scale for overlay comparison.
    private func normalizePoints() {
        guard !analysisA.points.isEmpty && !analysisB.points.isEmpty else {
            normalizedPointsA = analysisA.points
            normalizedPointsB = analysisB.points
            return
        }

        let allYValues = analysisA.points.map(\.y) + analysisB.points.map(\.y)
        guard let minY = allYValues.min(), let maxY = allYValues.max() else {
            normalizedPointsA = analysisA.points
            normalizedPointsB = analysisB.points
            return
        }

        let range = maxY - minY
        guard range > 0 else {
            normalizedPointsA = analysisA.points
            normalizedPointsB = analysisB.points
            return
        }

        normalizedPointsA = analysisA.points.map { point in
            BarPathPoint(
                id: point.id,
                x: point.x,
                y: (point.y - minY) / range,
                timestamp: point.timestamp,
                confidence: point.confidence,
                detectionSource: point.detectionSource
            )
        }

        normalizedPointsB = analysisB.points.map { point in
            BarPathPoint(
                id: point.id,
                x: point.x,
                y: (point.y - minY) / range,
                timestamp: point.timestamp,
                confidence: point.confidence,
                detectionSource: point.detectionSource
            )
        }
    }

    // MARK: - Computed Properties

    /// Formatted difference in peak velocity between the two analyses.
    var peakVelocityDifference: String {
        let diff = analysisA.metrics.peakVelocity - analysisB.metrics.peakVelocity
        return formatDifference(diff)
    }

    /// Formatted difference in average velocity between the two analyses.
    var averageVelocityDifference: String {
        let diff = analysisA.metrics.averageVelocity - analysisB.metrics.averageVelocity
        return formatDifference(diff)
    }

    /// Formatted difference in displacement between the two analyses.
    var displacementDifference: String {
        let diff = analysisA.metrics.totalVerticalDisplacement - analysisB.metrics.totalVerticalDisplacement
        return formatDifference(diff)
    }

    /// Formatted difference in drift between the two analyses.
    var driftDifference: String {
        let diff = analysisA.metrics.maxHorizontalDrift - analysisB.metrics.maxHorizontalDrift
        return formatDifference(diff)
    }

    /// Formatted difference in consistency between the two analyses.
    var consistencyDifference: String {
        let diff = (analysisA.metrics.consistency - analysisB.metrics.consistency) * 100
        return formatDifference(diff, suffix: "%")
    }

    /// Formatted difference in rep count between the two analyses.
    var repCountDifference: String {
        let diff = analysisA.metrics.repCount - analysisB.metrics.repCount
        return diff == 0 ? "—" : String(format: "%+d", diff)
    }

    // MARK: - Helpers

    private func formatDifference(_ value: Double, suffix: String = "") -> String {
        if abs(value) < 0.001 {
            return "—"
        }
        let sign = value > 0 ? "+" : ""
        return String(format: "\(sign)%.2f\(suffix)", value)
    }
}
