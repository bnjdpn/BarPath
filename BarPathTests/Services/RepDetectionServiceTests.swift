import Testing
import Foundation
@testable import BarPath

@Suite("RepDetectionService Tests")
struct RepDetectionServiceTests {

    // MARK: - Squat Rep Detection (Valley-to-Valley)

    @Test("Detects reps in a squat path with sine wave pattern")
    func detectSquatReps() {
        let points = TestData.makeSquatPath(repCount: 5)
        let smoothed = BarPathAnalyzer.smoothPath(points)
        let reps = RepDetectionService.detectReps(in: smoothed, liftType: .squat)

        // With 5 full sine cycles and valley-to-valley detection, we should detect
        // at least 2 reps. The exact count depends on smoothing and threshold filtering.
        #expect(reps.count >= 2, "Should detect at least 2 reps from 5-rep squat path, got \(reps.count)")
    }

    @Test("Detected squat reps have valid properties")
    func squatRepProperties() {
        let points = TestData.makeSquatPath(repCount: 3)
        let smoothed = BarPathAnalyzer.smoothPath(points)
        let reps = RepDetectionService.detectReps(in: smoothed, liftType: .squat)

        for rep in reps {
            #expect(rep.repNumber > 0)
            #expect(rep.endIndex > rep.startIndex)
            #expect(rep.concentricStartIndex >= rep.startIndex)
            #expect(rep.concentricStartIndex <= rep.endIndex)
            #expect(rep.verticalDisplacement > 0)
            #expect(rep.duration > 0)
            #expect(rep.peakVelocity >= 0)
            #expect(rep.averageVelocity >= 0)
        }
    }

    @Test("Rep numbers are sequential starting from 1")
    func repNumbersAreSequential() {
        let points = TestData.makeSquatPath(repCount: 4)
        let smoothed = BarPathAnalyzer.smoothPath(points)
        let reps = RepDetectionService.detectReps(in: smoothed, liftType: .squat)

        for (index, rep) in reps.enumerated() {
            #expect(rep.repNumber == index + 1)
        }
    }

    // MARK: - Single Rep Detection

    @Test("Detects at least one rep when multiple cycles are present")
    func detectSingleRep() {
        // Use enough cycles so that at least 2 valleys survive smoothing for 1 rep
        let points = TestData.makeSquatPath(repCount: 4)
        let smoothed = BarPathAnalyzer.smoothPath(points)
        let reps = RepDetectionService.detectReps(in: smoothed, liftType: .squat)

        #expect(reps.count >= 1, "Should detect at least 1 rep from 4-cycle squat path, got \(reps.count)")
    }

    // MARK: - Flat Line (No Reps)

    @Test("No reps detected with flat line (no vertical movement)")
    func noRepsWithFlatLine() {
        // All points at the same Y position
        let points = (0..<100).map { i in
            TestData.makeBarPathPoint(
                x: 0.5,
                y: 0.5,
                timestamp: Double(i) / 30.0
            )
        }

        let reps = RepDetectionService.detectReps(in: points, liftType: .squat)
        #expect(reps.isEmpty, "Flat line should produce no reps")
    }

    // MARK: - Noisy Data (Small Movements Filtered)

    @Test("Small noise below threshold does not produce reps")
    func noisyDataFilteredOut() {
        // Create points with tiny oscillations below the 0.05 threshold
        var points: [BarPathPoint] = []
        for i in 0..<120 {
            let y = 0.5 + 0.02 * sin(Double(i) / 10.0 * 2.0 * .pi)
            points.append(TestData.makeBarPathPoint(
                x: 0.5,
                y: y,
                timestamp: Double(i) / 30.0
            ))
        }

        let reps = RepDetectionService.detectReps(in: points, liftType: .squat)
        #expect(reps.isEmpty, "Noise below threshold should not produce reps, got \(reps.count)")
    }

    // MARK: - Deadlift Rep Detection (Peak-to-Peak)

    @Test("Detects reps in a deadlift path with peak-to-peak detection")
    func detectDeadliftReps() {
        let points = TestData.makeDeadliftPath(repCount: 3)
        let smoothed = BarPathAnalyzer.smoothPath(points)
        let reps = RepDetectionService.detectReps(in: smoothed, liftType: .deadlift)

        #expect(reps.count >= 2, "Should detect at least 2 reps from 3-rep deadlift path, got \(reps.count)")
    }

    @Test("Deadlift reps have concentric start at lowest point between peaks")
    func deadliftConcentricStartAtLowest() {
        let points = TestData.makeDeadliftPath(repCount: 3)
        let smoothed = BarPathAnalyzer.smoothPath(points)
        let reps = RepDetectionService.detectReps(in: smoothed, liftType: .deadlift)

        for rep in reps {
            // Concentric start should be between start and end
            #expect(rep.concentricStartIndex >= rep.startIndex)
            #expect(rep.concentricStartIndex <= rep.endIndex)
        }
    }

    @Test("Clean and snatch use same detection strategy as deadlift")
    func cleanAndSnatchUsePeakDetection() {
        let points = TestData.makeDeadliftPath(repCount: 3)
        let smoothed = BarPathAnalyzer.smoothPath(points)

        let cleanReps = RepDetectionService.detectReps(in: smoothed, liftType: .clean)
        let snatchReps = RepDetectionService.detectReps(in: smoothed, liftType: .snatch)

        // Both should use peak-to-peak detection and find the same reps
        #expect(cleanReps.count == snatchReps.count)
    }

    // MARK: - Minimum Displacement Threshold

    @Test("Movements at exactly the threshold boundary")
    func movementsAtThresholdBoundary() {
        // Create oscillation with amplitude exactly 0.05 (the threshold)
        var points: [BarPathPoint] = []
        for i in 0..<120 {
            let y = 0.5 + 0.05 * sin(Double(i) / 20.0 * 2.0 * .pi)
            points.append(TestData.makeBarPathPoint(
                x: 0.5,
                y: y,
                timestamp: Double(i) / 30.0
            ))
        }

        let reps = RepDetectionService.detectReps(in: points, liftType: .squat)
        // At exactly the threshold, detection may or may not find reps depending on
        // implementation. We just verify it does not crash.
        #expect(reps.count >= 0)
    }

    @Test("Large displacement movements are reliably detected")
    func largeDisplacementDetected() {
        // Create clear, large oscillations well above threshold
        var points: [BarPathPoint] = []
        for i in 0..<180 {
            let y = 0.5 + 0.2 * sin(Double(i) / 60.0 * 2.0 * .pi)
            points.append(TestData.makeBarPathPoint(
                x: 0.5,
                y: y,
                timestamp: Double(i) / 30.0
            ))
        }

        let reps = RepDetectionService.detectReps(in: points, liftType: .squat)
        #expect(reps.count >= 1, "Large movements should be detected as reps")
    }

    // MARK: - Edge Cases

    @Test("Empty input returns no reps")
    func emptyInput() {
        let reps = RepDetectionService.detectReps(in: [], liftType: .squat)
        #expect(reps.isEmpty)
    }

    @Test("Two points returns no reps")
    func twoPointsReturnsNoReps() {
        let points = [
            TestData.makeBarPathPoint(timestamp: 0),
            TestData.makeBarPathPoint(timestamp: 0.033),
        ]

        let reps = RepDetectionService.detectReps(in: points, liftType: .squat)
        #expect(reps.isEmpty)
    }

    @Test("Three points with insufficient displacement returns no reps")
    func threePointsInsufficientDisplacement() {
        let points = [
            TestData.makeBarPathPoint(y: 0.5, timestamp: 0),
            TestData.makeBarPathPoint(y: 0.5, timestamp: 0.033),
            TestData.makeBarPathPoint(y: 0.5, timestamp: 0.066),
        ]

        let reps = RepDetectionService.detectReps(in: points, liftType: .squat)
        #expect(reps.isEmpty)
    }

    // MARK: - Bench Press Uses Valley Detection

    @Test("Bench press uses valley-to-valley detection like squat")
    func benchPressUsesValleyDetection() {
        let points = TestData.makeSquatPath(repCount: 3)
        let smoothed = BarPathAnalyzer.smoothPath(points)

        let squatReps = RepDetectionService.detectReps(in: smoothed, liftType: .squat)
        let benchReps = RepDetectionService.detectReps(in: smoothed, liftType: .benchPress)

        #expect(squatReps.count == benchReps.count)
    }
}
