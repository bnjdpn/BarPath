import Testing
import Foundation
@testable import BarPath

@Suite("BarPathAnalyzer Tests")
struct BarPathAnalyzerTests {

    // MARK: - Smoothing

    @Test("smoothPath with known data points produces averaged values")
    func smoothPathWithKnownData() {
        // Create a set of points with known x/y that we can verify averaging on.
        // 10 points: indices 0..9. With smoothingWindowSize=5, halfWindow=2.
        let points = (0..<10).map { i in
            TestData.makeBarPathPoint(
                x: Double(i) * 0.1,       // 0.0, 0.1, 0.2, ..., 0.9
                y: Double(i % 2) * 0.1,   // alternating 0.0, 0.1, 0.0, 0.1, ...
                timestamp: Double(i) / 30.0,
                confidence: 0.9
            )
        }

        let smoothed = BarPathAnalyzer.smoothPath(points)

        #expect(smoothed.count == points.count)

        // Middle point (index 5) should average indices 3,4,5,6,7
        // x: (0.3+0.4+0.5+0.6+0.7)/5 = 0.5
        #expect(abs(smoothed[5].x - 0.5) < 0.001)

        // Timestamps should be preserved
        for i in 0..<points.count {
            #expect(smoothed[i].timestamp == points[i].timestamp)
        }
    }

    @Test("smoothPath preserves timestamps and confidence")
    func smoothPathPreservesMetadata() {
        let points = TestData.makeSquatPath(repCount: 1)
        let smoothed = BarPathAnalyzer.smoothPath(points)

        for i in 0..<points.count {
            #expect(smoothed[i].timestamp == points[i].timestamp)
            #expect(smoothed[i].confidence == points[i].confidence)
            #expect(smoothed[i].id == points[i].id)
        }
    }

    @Test("smoothPath returns input unchanged when too few points")
    func smoothPathWithFewPoints() {
        let points = [
            TestData.makeBarPathPoint(x: 0.1, y: 0.2, timestamp: 0),
            TestData.makeBarPathPoint(x: 0.3, y: 0.4, timestamp: 0.033),
            TestData.makeBarPathPoint(x: 0.5, y: 0.6, timestamp: 0.066),
        ]

        let smoothed = BarPathAnalyzer.smoothPath(points)

        // With <= smoothingWindowSize (5), path is returned unchanged
        #expect(smoothed.count == 3)
        #expect(smoothed[0].x == points[0].x)
        #expect(smoothed[1].x == points[1].x)
        #expect(smoothed[2].x == points[2].x)
    }

    @Test("Smoothing reduces noise in a noisy path")
    func smoothingReducesNoise() {
        // Create a straight line at y=0.5 with random noise
        let baseY = 0.5
        var points: [BarPathPoint] = []
        for i in 0..<50 {
            let noise = (i % 2 == 0) ? 0.05 : -0.05
            points.append(TestData.makeBarPathPoint(
                x: 0.5,
                y: baseY + noise,
                timestamp: Double(i) / 30.0
            ))
        }

        let smoothed = BarPathAnalyzer.smoothPath(points)

        // After smoothing, the variance should be reduced
        let originalVariance = points.map { ($0.y - baseY) * ($0.y - baseY) }.reduce(0, +) / Double(points.count)
        let smoothedVariance = smoothed.map { ($0.y - baseY) * ($0.y - baseY) }.reduce(0, +) / Double(smoothed.count)

        #expect(smoothedVariance < originalVariance, "Smoothing should reduce variance")
    }

    // MARK: - Velocity Calculation

    @Test("calculateVelocities with known data points")
    func velocityCalculationWithKnownData() {
        let points = [
            TestData.makeBarPathPoint(x: 0.0, y: 0.0, timestamp: 0.0),
            TestData.makeBarPathPoint(x: 0.1, y: 0.0, timestamp: 1.0),
            TestData.makeBarPathPoint(x: 0.1, y: 0.1, timestamp: 2.0),
        ]

        let velocities = BarPathAnalyzer.calculateVelocities(points)

        #expect(velocities.count == 3)
        #expect(velocities[0] == 0.0) // First point always 0
        #expect(abs(velocities[1] - 0.1) < 0.001) // dx=0.1, dy=0, dt=1 -> v=0.1
        #expect(abs(velocities[2] - 0.1) < 0.001) // dx=0, dy=0.1, dt=1 -> v=0.1
    }

    @Test("calculateVelocities with single point returns zero")
    func velocityWithSinglePoint() {
        let points = [TestData.makeBarPathPoint()]
        let velocities = BarPathAnalyzer.calculateVelocities(points)

        #expect(velocities.count == 1)
        #expect(velocities[0] == 0.0)
    }

    @Test("calculateVelocities with empty input returns empty array")
    func velocityWithEmptyInput() {
        let velocities = BarPathAnalyzer.calculateVelocities([])
        #expect(velocities.isEmpty)
    }

    @Test("calculateVelocities handles zero time delta gracefully")
    func velocityWithZeroTimeDelta() {
        let points = [
            TestData.makeBarPathPoint(x: 0.0, y: 0.0, timestamp: 1.0),
            TestData.makeBarPathPoint(x: 0.5, y: 0.5, timestamp: 1.0), // same timestamp
        ]

        let velocities = BarPathAnalyzer.calculateVelocities(points)

        #expect(velocities.count == 2)
        #expect(velocities[1] == 0.0) // Zero time delta should produce zero velocity
    }

    @Test("calculateVelocities with diagonal movement")
    func velocityWithDiagonalMovement() {
        let points = [
            TestData.makeBarPathPoint(x: 0.0, y: 0.0, timestamp: 0.0),
            TestData.makeBarPathPoint(x: 0.3, y: 0.4, timestamp: 1.0),
        ]

        let velocities = BarPathAnalyzer.calculateVelocities(points)

        // Distance = sqrt(0.09 + 0.16) = sqrt(0.25) = 0.5, dt=1
        #expect(abs(velocities[1] - 0.5) < 0.001)
    }

    // MARK: - Horizontal Drift

    @Test("calculateHorizontalDrift with known drift")
    func horizontalDriftCalculation() {
        let points = [
            TestData.makeBarPathPoint(x: 0.50, y: 0.3, timestamp: 0),
            TestData.makeBarPathPoint(x: 0.52, y: 0.4, timestamp: 0.033),
            TestData.makeBarPathPoint(x: 0.55, y: 0.5, timestamp: 0.066),
            TestData.makeBarPathPoint(x: 0.48, y: 0.4, timestamp: 0.1),
            TestData.makeBarPathPoint(x: 0.51, y: 0.3, timestamp: 0.133),
        ]

        let drift = BarPathAnalyzer.calculateHorizontalDrift(
            points: points,
            startIndex: 0,
            endIndex: 5
        )

        // Max deviation from startX (0.50): 0.55 - 0.50 = 0.05
        #expect(abs(drift - 0.05) < 0.001)
    }

    @Test("calculateHorizontalDrift with no drift")
    func horizontalDriftWithNoDrift() {
        let points = [
            TestData.makeBarPathPoint(x: 0.5, y: 0.3, timestamp: 0),
            TestData.makeBarPathPoint(x: 0.5, y: 0.4, timestamp: 0.033),
            TestData.makeBarPathPoint(x: 0.5, y: 0.5, timestamp: 0.066),
        ]

        let drift = BarPathAnalyzer.calculateHorizontalDrift(
            points: points,
            startIndex: 0,
            endIndex: 3
        )

        #expect(drift == 0.0)
    }

    @Test("calculateHorizontalDrift with invalid indices returns zero")
    func horizontalDriftInvalidIndices() {
        let points = [TestData.makeBarPathPoint()]

        let drift = BarPathAnalyzer.calculateHorizontalDrift(
            points: points,
            startIndex: 5,
            endIndex: 10
        )

        #expect(drift == 0.0)
    }

    // MARK: - Full Analysis

    @Test("analyze produces valid analysis with calibration data")
    func analyzeWithCalibration() {
        let points = TestData.makeSquatPath(repCount: 3)
        let calibration = TestData.makeCalibration()

        let analysis = BarPathAnalyzer.analyze(
            points: points,
            liftType: .squat,
            calibration: calibration
        )

        #expect(analysis.liftType == .squat)
        #expect(!analysis.points.isEmpty)
        #expect(analysis.duration > 0)
    }

    @Test("analyze produces valid analysis without calibration")
    func analyzeWithoutCalibration() {
        let points = TestData.makeSquatPath(repCount: 2)

        let analysis = BarPathAnalyzer.analyze(
            points: points,
            liftType: .squat,
            calibration: nil
        )

        #expect(analysis.liftType == .squat)
        #expect(analysis.points.count == points.count)
        #expect(analysis.videoURL == nil)
    }

    @Test("analyze with empty input returns analysis with no reps")
    func analyzeWithEmptyInput() {
        let analysis = BarPathAnalyzer.analyze(
            points: [],
            liftType: .squat
        )

        #expect(analysis.points.isEmpty)
        #expect(analysis.reps.isEmpty)
        #expect(analysis.metrics.repCount == 0)
        #expect(analysis.duration == 0)
    }

    @Test("analyze with single point returns analysis with no reps")
    func analyzeWithSinglePoint() {
        let points = [TestData.makeBarPathPoint()]

        let analysis = BarPathAnalyzer.analyze(
            points: points,
            liftType: .squat
        )

        #expect(analysis.points.count == 1)
        #expect(analysis.reps.isEmpty)
        #expect(analysis.duration == 0)
    }

    // MARK: - Duration Computation

    @Test("computeDuration returns correct time span")
    func computeDuration() {
        let points = [
            TestData.makeBarPathPoint(timestamp: 1.5),
            TestData.makeBarPathPoint(timestamp: 2.0),
            TestData.makeBarPathPoint(timestamp: 4.5),
        ]

        let duration = BarPathAnalyzer.computeDuration(from: points)
        #expect(abs(duration - 3.0) < 0.001)
    }

    @Test("computeDuration with empty array returns zero")
    func computeDurationEmpty() {
        let duration = BarPathAnalyzer.computeDuration(from: [])
        #expect(duration == 0)
    }

    @Test("computeDuration with single point returns zero")
    func computeDurationSinglePoint() {
        let duration = BarPathAnalyzer.computeDuration(from: [TestData.makeBarPathPoint(timestamp: 5.0)])
        #expect(duration == 0)
    }
}
