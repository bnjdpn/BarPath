import Foundation

/// Aggregate metrics computed across all reps in a bar path analysis.
struct AnalysisMetrics: Codable, Sendable {

    // MARK: - Properties

    let peakVelocity: Double
    let averageVelocity: Double
    let totalVerticalDisplacement: Double
    let maxHorizontalDrift: Double
    let averageHorizontalDrift: Double
    let consistency: Double
    let repCount: Int
    let averageRepDuration: TimeInterval

    // MARK: - Factory

    /// Calculates aggregate metrics from an array of rep segments.
    ///
    /// - Parameter reps: The rep segments to aggregate.
    /// - Returns: A fully populated `AnalysisMetrics` instance.
    static func calculate(from reps: [RepSegment]) -> AnalysisMetrics {
        guard !reps.isEmpty else {
            return AnalysisMetrics(
                peakVelocity: 0,
                averageVelocity: 0,
                totalVerticalDisplacement: 0,
                maxHorizontalDrift: 0,
                averageHorizontalDrift: 0,
                consistency: 0,
                repCount: 0,
                averageRepDuration: 0
            )
        }

        let peakVelocity = reps.map(\.peakVelocity).max() ?? 0
        let averageVelocity = reps.map(\.averageVelocity).reduce(0, +) / Double(reps.count)
        let totalVerticalDisplacement = reps.map(\.verticalDisplacement).reduce(0, +)
        let maxHorizontalDrift = reps.map(\.horizontalDrift).max() ?? 0
        let averageHorizontalDrift = reps.map(\.horizontalDrift).reduce(0, +) / Double(reps.count)
        let averageRepDuration = reps.map(\.duration).reduce(0, +) / Double(reps.count)
        let consistency = Self.calculateConsistency(from: reps)

        return AnalysisMetrics(
            peakVelocity: peakVelocity,
            averageVelocity: averageVelocity,
            totalVerticalDisplacement: totalVerticalDisplacement,
            maxHorizontalDrift: maxHorizontalDrift,
            averageHorizontalDrift: averageHorizontalDrift,
            consistency: consistency,
            repCount: reps.count,
            averageRepDuration: averageRepDuration
        )
    }

    // MARK: - Private Helpers

    /// Computes a consistency score (0-1) measuring how similar reps are to each other.
    /// Uses coefficient of variation of vertical displacement and duration across reps.
    /// A score of 1.0 means perfectly consistent; lower values indicate more variation.
    private static func calculateConsistency(from reps: [RepSegment]) -> Double {
        guard reps.count > 1 else { return 1.0 }

        let displacements = reps.map(\.verticalDisplacement)
        let durations = reps.map(\.duration)

        let displacementCV = coefficientOfVariation(displacements)
        let durationCV = coefficientOfVariation(durations)

        let averageCV = (displacementCV + durationCV) / 2.0
        return max(0, min(1, 1.0 - averageCV))
    }

    /// Returns the coefficient of variation (stddev / mean) for a set of values.
    private static func coefficientOfVariation(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        guard mean > 0 else { return 0 }
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        return standardDeviation / mean
    }
}
