import Foundation

/// Analyzes raw pose-detected bar path points into a complete analysis result.
///
/// All calculation methods are pure functions that take inputs and return outputs,
/// making them straightforward to test without side effects.
struct BarPathAnalyzer {

    // MARK: - Constants

    /// Number of points on each side of the center used for the moving average window.
    private static let smoothingWindowSize = 5

    // MARK: - Public API

    /// Produces a complete bar path analysis from raw tracked points.
    ///
    /// - Parameters:
    ///   - points: The raw bar path points captured from pose detection.
    ///   - liftType: The type of lift being analyzed.
    ///   - calibration: Optional calibration data for real-world unit conversion.
    ///   - videoURL: Optional URL to the source video file.
    /// - Returns: A fully populated `BarPathAnalysis`.
    static func analyze(
        points: [BarPathPoint],
        liftType: LiftType,
        calibration: CalibrationData? = nil,
        videoURL: URL? = nil
    ) -> BarPathAnalysis {
        let smoothed = smoothPath(points)
        let reps = RepDetectionService.detectReps(in: smoothed, liftType: liftType)
        let metrics = AnalysisMetrics.calculate(from: reps)
        let duration = computeDuration(from: points)

        return BarPathAnalysis(
            liftType: liftType,
            points: smoothed,
            reps: reps,
            metrics: metrics,
            videoURL: videoURL,
            duration: duration
        )
    }

    // MARK: - Smoothing

    /// Applies a simple moving average to smooth the bar path coordinates.
    ///
    /// For each point, the X and Y values are averaged over a window of up to
    /// `smoothingWindowSize` neighbors on each side. Points near the edges of the
    /// array use a smaller, asymmetric window. Timestamp and confidence are preserved
    /// from the original point.
    ///
    /// - Parameter points: The raw bar path points.
    /// - Returns: A new array of smoothed bar path points.
    static func smoothPath(_ points: [BarPathPoint]) -> [BarPathPoint] {
        guard points.count > smoothingWindowSize else { return points }

        let halfWindow = smoothingWindowSize / 2

        return points.enumerated().map { index, point in
            let lowerBound = max(0, index - halfWindow)
            let upperBound = min(points.count - 1, index + halfWindow)
            let window = points[lowerBound...upperBound]

            let averageX = window.map(\.x).reduce(0, +) / Double(window.count)
            let averageY = window.map(\.y).reduce(0, +) / Double(window.count)

            return BarPathPoint(
                id: point.id,
                x: averageX,
                y: averageY,
                timestamp: point.timestamp,
                confidence: point.confidence
            )
        }
    }

    // MARK: - Velocity

    /// Calculates frame-to-frame velocity for each point based on Euclidean distance
    /// divided by the time delta between consecutive frames.
    ///
    /// The first point receives a velocity of zero. Units are normalized coordinates
    /// per second.
    ///
    /// - Parameter points: The smoothed bar path points.
    /// - Returns: An array of velocities corresponding to each point.
    static func calculateVelocities(_ points: [BarPathPoint]) -> [Double] {
        guard points.count > 1 else { return Array(repeating: 0, count: points.count) }

        var velocities: [Double] = [0]

        for i in 1..<points.count {
            let dx = points[i].x - points[i - 1].x
            let dy = points[i].y - points[i - 1].y
            let distance = sqrt(dx * dx + dy * dy)
            let dt = points[i].timestamp - points[i - 1].timestamp

            if dt > 0 {
                velocities.append(distance / dt)
            } else {
                velocities.append(0)
            }
        }

        return velocities
    }

    // MARK: - Horizontal Drift

    /// Calculates the horizontal drift for a rep segment.
    ///
    /// Drift is defined as the maximum absolute horizontal deviation from the starting
    /// X position within the segment.
    ///
    /// - Parameters:
    ///   - points: The full array of smoothed bar path points.
    ///   - startIndex: The index where the rep begins.
    ///   - endIndex: The index where the rep ends.
    /// - Returns: The maximum horizontal drift in normalized coordinates.
    static func calculateHorizontalDrift(
        points: [BarPathPoint],
        startIndex: Int,
        endIndex: Int
    ) -> Double {
        guard startIndex < endIndex, startIndex < points.count, endIndex <= points.count else {
            return 0
        }

        let segment = points[startIndex..<endIndex]
        guard let startX = segment.first?.x else { return 0 }

        return segment.map { abs($0.x - startX) }.max() ?? 0
    }

    // MARK: - Helpers

    /// Computes the total duration spanned by an array of points.
    ///
    /// - Parameter points: The bar path points.
    /// - Returns: The time interval from the first to the last point in seconds.
    static func computeDuration(from points: [BarPathPoint]) -> TimeInterval {
        guard let first = points.first, let last = points.last else { return 0 }
        return last.timestamp - first.timestamp
    }
}
