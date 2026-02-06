import Foundation
@testable import BarPath

/// Static factory for generating test data used across the test suite.
enum TestData {

    // MARK: - BarPathPoint

    /// Creates a single bar path point with sensible defaults.
    static func makeBarPathPoint(
        x: Double = 0.5,
        y: Double = 0.5,
        timestamp: TimeInterval = 0.0,
        confidence: Float = 0.9
    ) -> BarPathPoint {
        BarPathPoint(x: x, y: y, timestamp: timestamp, confidence: confidence)
    }

    // MARK: - Squat Path

    /// Generates a realistic squat bar path with smooth sine-wave-like vertical movement.
    ///
    /// In a squat, the bar starts high (y ~ 0.3 in normalized coords, since y is flipped),
    /// descends to a valley (y ~ 0.6), then returns. Each rep is a full down-up cycle.
    /// The path includes slight horizontal drift to simulate real-world bar movement.
    ///
    /// - Parameter repCount: Number of complete reps to generate.
    /// - Returns: An array of bar path points representing the squat movement.
    static func makeSquatPath(repCount: Int) -> [BarPathPoint] {
        let pointsPerRep = 60
        let totalPoints = pointsPerRep * repCount + 1
        let fps: Double = 30.0

        var points: [BarPathPoint] = []

        for i in 0..<totalPoints {
            let t = Double(i) / fps
            let phase = Double(i) / Double(pointsPerRep) * 2.0 * .pi

            // Squat: bar descends then ascends. Y increases on descent (top-left origin).
            // Base position at y=0.3, amplitude 0.15 (descends to ~0.45, ascends to ~0.3).
            let y = 0.3 + 0.15 * (1.0 - cos(phase))
            // Small horizontal drift: subtle sine wave at half frequency
            let x = 0.5 + 0.01 * sin(phase * 0.5)

            points.append(makeBarPathPoint(x: x, y: y, timestamp: t, confidence: 0.9))
        }

        return points
    }

    // MARK: - Deadlift Path

    /// Generates a deadlift bar path where the bar starts low and rises to lockout.
    ///
    /// In a deadlift, the bar starts near the ground (high y in top-left origin),
    /// rises to lockout (lower y), then returns. Each rep is a full up-down cycle.
    ///
    /// - Parameter repCount: Number of complete reps to generate.
    /// - Returns: An array of bar path points representing the deadlift movement.
    static func makeDeadliftPath(repCount: Int) -> [BarPathPoint] {
        let pointsPerRep = 60
        let totalPoints = pointsPerRep * repCount + 1
        let fps: Double = 30.0

        var points: [BarPathPoint] = []

        for i in 0..<totalPoints {
            let t = Double(i) / fps
            let phase = Double(i) / Double(pointsPerRep) * 2.0 * .pi

            // Deadlift: bar rises from floor (y=0.7) to lockout (y=0.4).
            // Using cosine so peaks (low y values = high position) are at 0, 2pi, etc.
            let y = 0.55 - 0.15 * cos(phase)
            // Slight horizontal movement toward the body during the pull
            let x = 0.5 - 0.02 * sin(phase)

            points.append(makeBarPathPoint(x: x, y: y, timestamp: t, confidence: 0.85))
        }

        return points
    }

    // MARK: - RepSegment

    /// Creates a rep segment with sensible defaults.
    static func makeRepSegment(
        repNumber: Int = 1,
        startIndex: Int = 0,
        endIndex: Int = 60,
        concentricStartIndex: Int = 30,
        peakVelocity: Double = 1.2,
        averageVelocity: Double = 0.6,
        verticalDisplacement: Double = 0.3,
        horizontalDrift: Double = 0.02,
        duration: TimeInterval = 2.0
    ) -> RepSegment {
        RepSegment(
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

    // MARK: - BarPathAnalysis

    /// Creates a complete analysis with sample data.
    static func makeAnalysis(
        liftType: LiftType = .squat,
        repCount: Int = 3,
        notes: String = ""
    ) -> BarPathAnalysis {
        let points = makeSquatPath(repCount: repCount)
        let reps: [RepSegment] = (1...repCount).map { i in
            let start = (i - 1) * 60
            let end = i * 60
            let concentricStart = start + 30
            let peak = 1.2 + Double(i) * 0.05
            let avg = 0.6 + Double(i) * 0.02
            return makeRepSegment(
                repNumber: i,
                startIndex: start,
                endIndex: end,
                concentricStartIndex: concentricStart,
                peakVelocity: peak,
                averageVelocity: avg,
                verticalDisplacement: 0.3,
                horizontalDrift: 0.02,
                duration: 2.0
            )
        }
        let metrics = AnalysisMetrics.calculate(from: reps)

        return BarPathAnalysis(
            liftType: liftType,
            points: points,
            reps: reps,
            metrics: metrics,
            duration: points.last?.timestamp ?? 0.0,
            notes: notes
        )
    }

    // MARK: - CalibrationData

    /// Creates calibration data with typical values for a standard plate calibration.
    static func makeCalibration(
        method: CalibrationMethod = .plateSize,
        referenceValueMeters: Double = 0.45,
        pixelsPerMeter: Double = 500.0
    ) -> CalibrationData {
        CalibrationData(
            method: method,
            referenceValueMeters: referenceValueMeters,
            pixelsPerMeter: pixelsPerMeter
        )
    }

    // MARK: - Flat Path (No Movement)

    /// Creates a path with no significant vertical movement, useful for testing
    /// that rep detection properly returns zero reps.
    static func makeFlatPath(pointCount: Int = 100) -> [BarPathPoint] {
        (0..<pointCount).map { i in
            makeBarPathPoint(
                x: 0.5 + Double.random(in: -0.005...0.005),
                y: 0.5 + Double.random(in: -0.005...0.005),
                timestamp: Double(i) / 30.0,
                confidence: 0.9
            )
        }
    }

    // MARK: - Noisy Path

    /// Creates a path with small random noise that should not be detected as reps.
    static func makeNoisyPath(pointCount: Int = 120) -> [BarPathPoint] {
        (0..<pointCount).map { i in
            makeBarPathPoint(
                x: 0.5 + Double.random(in: -0.02...0.02),
                y: 0.5 + Double.random(in: -0.02...0.02),
                timestamp: Double(i) / 30.0,
                confidence: 0.9
            )
        }
    }
}
