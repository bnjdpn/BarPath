import Foundation

/// Protocol abstracting the bar path analysis pipeline that converts tracked points
/// into rep segments and aggregate metrics.
/// Enables dependency injection and testability.
protocol BarPathAnalyzing: Sendable {

    /// Analyzes an array of tracked bar path points to detect reps and compute metrics.
    ///
    /// - Parameters:
    ///   - points: The tracked `BarPathPoint` array from pose detection.
    ///   - liftType: The type of lift being analyzed, used to tune detection heuristics.
    ///   - calibration: Optional calibration data for converting to real-world units.
    /// - Returns: A tuple of detected rep segments and computed aggregate metrics.
    func analyze(
        points: [BarPathPoint],
        liftType: LiftType,
        calibration: CalibrationData?
    ) async throws -> (reps: [RepSegment], metrics: AnalysisMetrics)
}
