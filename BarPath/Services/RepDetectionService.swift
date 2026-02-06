import Foundation

/// Detects individual repetitions from a smoothed bar path by identifying peaks and
/// valleys in the vertical (Y) coordinate.
///
/// All methods are static pure functions for straightforward testability.
struct RepDetectionService {

    // MARK: - Constants

    /// Minimum vertical displacement (in normalized coordinates) required to consider
    /// a peak or valley significant. Smaller movements are treated as noise.
    private static let minimumDisplacementThreshold: Double = 0.05

    /// Minimum duration in seconds for a rep to be considered valid.
    private static let minimumRepDuration: TimeInterval = 0.3

    /// Maximum duration in seconds for a rep to be considered valid.
    private static let maximumRepDuration: TimeInterval = 10.0

    // MARK: - Public API

    /// Detects reps from a smoothed bar path.
    ///
    /// The detection strategy depends on the lift type:
    /// - **Squat / Bench Press / Overhead Press / Row / Other:** A rep is one
    ///   valley-to-valley cycle. The bar starts high, descends to a valley (bottom of
    ///   the eccentric phase), then rises back. The concentric start is the valley.
    /// - **Deadlift / Clean / Snatch:** A rep is one peak-to-peak cycle. The bar starts
    ///   low, rises to a peak (top of the concentric phase), then descends. The
    ///   concentric start is the beginning of the upward movement.
    ///
    /// - Parameters:
    ///   - points: The smoothed bar path points.
    ///   - liftType: The type of lift, which determines the detection strategy.
    /// - Returns: An array of `RepSegment` values describing each detected rep.
    static func detectReps(in points: [BarPathPoint], liftType: LiftType) -> [RepSegment] {
        guard points.count > 2 else { return [] }

        let yValues = points.map(\.y)

        let reps: [RepSegment]

        switch liftType {
        case .deadlift, .clean, .snatch:
            reps = detectPeakToPeakReps(points: points, yValues: yValues)
        case .squat, .benchPress, .overheadPress, .row, .other:
            reps = detectValleyToValleyReps(points: points, yValues: yValues)
        }

        return filterAndRenumber(reps)
    }

    // MARK: - Valley-to-Valley Detection

    /// Detects reps as valley-to-valley cycles.
    ///
    /// In movements like squats and bench press, the bar descends from a starting
    /// position, reaches a low point (valley), then returns upward. Each pair of
    /// consecutive valleys defines a single rep.
    ///
    /// - Parameters:
    ///   - points: The smoothed bar path points.
    ///   - yValues: The Y coordinates extracted from the points.
    /// - Returns: An array of `RepSegment` values.
    private static func detectValleyToValleyReps(
        points: [BarPathPoint],
        yValues: [Double]
    ) -> [RepSegment] {
        let valleys = findValleys(in: yValues)
        guard valleys.count >= 2 else { return [] }

        var reps: [RepSegment] = []

        for i in 0..<(valleys.count - 1) {
            let startIndex = valleys[i]
            let endIndex = valleys[i + 1]

            // The concentric start is the valley itself (lowest point).
            let concentricStartIndex = startIndex

            let rep = buildRepSegment(
                repNumber: reps.count + 1,
                startIndex: startIndex,
                endIndex: endIndex,
                concentricStartIndex: concentricStartIndex,
                points: points
            )

            if let rep {
                reps.append(rep)
            }
        }

        return reps
    }

    // MARK: - Peak-to-Peak Detection

    /// Detects reps as peak-to-peak cycles.
    ///
    /// In movements like deadlifts, the bar starts on the ground, rises to a peak
    /// (lockout), then descends. Each pair of consecutive peaks defines a single rep.
    ///
    /// - Parameters:
    ///   - points: The smoothed bar path points.
    ///   - yValues: The Y coordinates extracted from the points.
    /// - Returns: An array of `RepSegment` values.
    private static func detectPeakToPeakReps(
        points: [BarPathPoint],
        yValues: [Double]
    ) -> [RepSegment] {
        let peaks = findPeaks(in: yValues)
        guard peaks.count >= 2 else { return [] }

        var reps: [RepSegment] = []

        for i in 0..<(peaks.count - 1) {
            let startIndex = peaks[i]
            let endIndex = peaks[i + 1]

            // For deadlift-style lifts, find the lowest point between two peaks
            // as the start of the concentric phase.
            let segmentSlice = Array(yValues[startIndex...endIndex])
            let localMinOffset = segmentSlice.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            let concentricStartIndex = startIndex + localMinOffset

            let rep = buildRepSegment(
                repNumber: reps.count + 1,
                startIndex: startIndex,
                endIndex: endIndex,
                concentricStartIndex: concentricStartIndex,
                points: points
            )

            if let rep {
                reps.append(rep)
            }
        }

        return reps
    }

    // MARK: - Peak / Valley Detection

    /// Finds indices of significant valleys (local minima) in the Y values.
    ///
    /// A valley must be lower than both its neighbors and must differ from the
    /// nearest peak by at least `minimumDisplacementThreshold`.
    ///
    /// - Parameter yValues: The Y coordinate values to analyze.
    /// - Returns: Sorted indices of detected valleys.
    private static func findValleys(in yValues: [Double]) -> [Int] {
        guard yValues.count > 2 else { return [] }

        var valleys: [Int] = []
        var lastPeakValue: Double = yValues[0]

        for i in 1..<(yValues.count - 1) {
            // Check for local minimum.
            if yValues[i] <= yValues[i - 1] && yValues[i] <= yValues[i + 1] {
                // Verify the valley is significantly lower than the last peak.
                if abs(lastPeakValue - yValues[i]) >= minimumDisplacementThreshold {
                    valleys.append(i)
                }
            }
            // Track the most recent peak value for displacement comparison.
            if yValues[i] >= yValues[i - 1] && yValues[i] >= yValues[i + 1] {
                lastPeakValue = yValues[i]
            }
        }

        return valleys
    }

    /// Finds indices of significant peaks (local maxima) in the Y values.
    ///
    /// A peak must be higher than both its neighbors and must differ from the
    /// nearest valley by at least `minimumDisplacementThreshold`.
    ///
    /// - Parameter yValues: The Y coordinate values to analyze.
    /// - Returns: Sorted indices of detected peaks.
    private static func findPeaks(in yValues: [Double]) -> [Int] {
        guard yValues.count > 2 else { return [] }

        var peaks: [Int] = []
        var lastValleyValue: Double = yValues[0]

        for i in 1..<(yValues.count - 1) {
            // Check for local maximum.
            if yValues[i] >= yValues[i - 1] && yValues[i] >= yValues[i + 1] {
                // Verify the peak is significantly higher than the last valley.
                if abs(yValues[i] - lastValleyValue) >= minimumDisplacementThreshold {
                    peaks.append(i)
                }
            }
            // Track the most recent valley value for displacement comparison.
            if yValues[i] <= yValues[i - 1] && yValues[i] <= yValues[i + 1] {
                lastValleyValue = yValues[i]
            }
        }

        return peaks
    }

    // MARK: - Duration Filtering

    /// Filters out reps whose duration falls outside the valid range and renumbers
    /// the remaining reps sequentially starting from 1.
    ///
    /// - Parameter reps: The unfiltered reps to validate.
    /// - Returns: A new array with invalid reps removed and rep numbers corrected.
    private static func filterAndRenumber(_ reps: [RepSegment]) -> [RepSegment] {
        var renumbered: [RepSegment] = []

        for rep in reps {
            guard rep.duration >= minimumRepDuration,
                  rep.duration <= maximumRepDuration else {
                continue
            }

            let corrected = RepSegment(
                repNumber: renumbered.count + 1,
                startIndex: rep.startIndex,
                endIndex: rep.endIndex,
                concentricStartIndex: rep.concentricStartIndex,
                peakVelocity: rep.peakVelocity,
                averageVelocity: rep.averageVelocity,
                verticalDisplacement: rep.verticalDisplacement,
                horizontalDrift: rep.horizontalDrift,
                duration: rep.duration
            )
            renumbered.append(corrected)
        }

        return renumbered
    }

    // MARK: - Rep Construction

    /// Builds a `RepSegment` from the given index range, computing velocity,
    /// displacement, drift, and duration metrics.
    ///
    /// Returns `nil` if the segment is too small or has no meaningful displacement.
    ///
    /// - Parameters:
    ///   - repNumber: The 1-based rep number.
    ///   - startIndex: The index where the rep begins in the points array.
    ///   - endIndex: The index where the rep ends.
    ///   - concentricStartIndex: The index marking the start of the concentric phase.
    ///   - points: The full array of smoothed bar path points.
    /// - Returns: A populated `RepSegment`, or `nil` if the segment is invalid.
    private static func buildRepSegment(
        repNumber: Int,
        startIndex: Int,
        endIndex: Int,
        concentricStartIndex: Int,
        points: [BarPathPoint]
    ) -> RepSegment? {
        guard endIndex > startIndex, endIndex < points.count else { return nil }

        let segment = Array(points[startIndex...endIndex])
        let velocities = BarPathAnalyzer.calculateVelocities(segment)

        let peakVelocity = velocities.max() ?? 0
        let averageVelocity = velocities.isEmpty ? 0 : velocities.reduce(0, +) / Double(velocities.count)

        let yValues = segment.map(\.y)
        let minY = yValues.min() ?? 0
        let maxY = yValues.max() ?? 0
        let verticalDisplacement = abs(maxY - minY)

        let horizontalDrift = BarPathAnalyzer.calculateHorizontalDrift(
            points: points,
            startIndex: startIndex,
            endIndex: endIndex
        )

        let duration = points[endIndex].timestamp - points[startIndex].timestamp

        return RepSegment(
            repNumber: repNumber,
            startIndex: startIndex,
            endIndex: endIndex,
            concentricStartIndex: concentricStartIndex,
            peakVelocity: peakVelocity,
            averageVelocity: averageVelocity,
            verticalDisplacement: verticalDisplacement,
            horizontalDrift: horizontalDrift,
            duration: duration
        )
    }
}
