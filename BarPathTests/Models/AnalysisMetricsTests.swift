import Testing
import Foundation
@testable import BarPath

@Suite("AnalysisMetrics Tests")
struct AnalysisMetricsTests {

    // MARK: - Calculate from Multiple Reps

    @Test("Calculate with multiple reps computes correct aggregate metrics")
    func calculateWithMultipleReps() {
        let reps = [
            TestData.makeRepSegment(
                repNumber: 1,
                peakVelocity: 1.0,
                averageVelocity: 0.5,
                verticalDisplacement: 0.3,
                horizontalDrift: 0.02,
                duration: 2.0
            ),
            TestData.makeRepSegment(
                repNumber: 2,
                peakVelocity: 1.4,
                averageVelocity: 0.7,
                verticalDisplacement: 0.3,
                horizontalDrift: 0.04,
                duration: 2.0
            ),
            TestData.makeRepSegment(
                repNumber: 3,
                peakVelocity: 1.2,
                averageVelocity: 0.6,
                verticalDisplacement: 0.3,
                horizontalDrift: 0.03,
                duration: 2.0
            ),
        ]

        let metrics = AnalysisMetrics.calculate(from: reps)

        #expect(metrics.repCount == 3)
        #expect(metrics.peakVelocity == 1.4)
        #expect(abs(metrics.averageVelocity - 0.6) < 0.001)
        #expect(abs(metrics.totalVerticalDisplacement - 0.9) < 0.001)
        #expect(metrics.maxHorizontalDrift == 0.04)
        #expect(abs(metrics.averageHorizontalDrift - 0.03) < 0.001)
        #expect(abs(metrics.averageRepDuration - 2.0) < 0.001)
    }

    @Test("Peak velocity is the maximum across all reps")
    func peakVelocityIsMax() {
        let reps = [
            TestData.makeRepSegment(repNumber: 1, peakVelocity: 0.8),
            TestData.makeRepSegment(repNumber: 2, peakVelocity: 1.5),
            TestData.makeRepSegment(repNumber: 3, peakVelocity: 1.2),
        ]

        let metrics = AnalysisMetrics.calculate(from: reps)
        #expect(metrics.peakVelocity == 1.5)
    }

    @Test("Average velocity is the mean of all rep averages")
    func averageVelocityIsMean() {
        let reps = [
            TestData.makeRepSegment(repNumber: 1, averageVelocity: 0.4),
            TestData.makeRepSegment(repNumber: 2, averageVelocity: 0.6),
            TestData.makeRepSegment(repNumber: 3, averageVelocity: 0.8),
        ]

        let metrics = AnalysisMetrics.calculate(from: reps)
        #expect(abs(metrics.averageVelocity - 0.6) < 0.001)
    }

    @Test("Total vertical displacement is the sum of all reps")
    func totalVerticalDisplacementIsSum() {
        let reps = [
            TestData.makeRepSegment(repNumber: 1, verticalDisplacement: 0.2),
            TestData.makeRepSegment(repNumber: 2, verticalDisplacement: 0.3),
            TestData.makeRepSegment(repNumber: 3, verticalDisplacement: 0.25),
        ]

        let metrics = AnalysisMetrics.calculate(from: reps)
        #expect(abs(metrics.totalVerticalDisplacement - 0.75) < 0.001)
    }

    // MARK: - Calculate with Single Rep

    @Test("Calculate with single rep returns that rep's values")
    func calculateWithSingleRep() {
        let reps = [
            TestData.makeRepSegment(
                repNumber: 1,
                peakVelocity: 1.3,
                averageVelocity: 0.65,
                verticalDisplacement: 0.28,
                horizontalDrift: 0.015,
                duration: 1.8
            ),
        ]

        let metrics = AnalysisMetrics.calculate(from: reps)

        #expect(metrics.repCount == 1)
        #expect(metrics.peakVelocity == 1.3)
        #expect(metrics.averageVelocity == 0.65)
        #expect(metrics.totalVerticalDisplacement == 0.28)
        #expect(metrics.maxHorizontalDrift == 0.015)
        #expect(metrics.averageHorizontalDrift == 0.015)
        #expect(metrics.averageRepDuration == 1.8)
    }

    @Test("Consistency is 1.0 for a single rep")
    func consistencyIsPerfectForSingleRep() {
        let reps = [TestData.makeRepSegment(repNumber: 1)]

        let metrics = AnalysisMetrics.calculate(from: reps)
        #expect(metrics.consistency == 1.0)
    }

    // MARK: - Calculate with Empty Array

    @Test("Calculate with empty array returns all zeros")
    func calculateWithEmptyArray() {
        let metrics = AnalysisMetrics.calculate(from: [])

        #expect(metrics.repCount == 0)
        #expect(metrics.peakVelocity == 0)
        #expect(metrics.averageVelocity == 0)
        #expect(metrics.totalVerticalDisplacement == 0)
        #expect(metrics.maxHorizontalDrift == 0)
        #expect(metrics.averageHorizontalDrift == 0)
        #expect(metrics.consistency == 0)
        #expect(metrics.averageRepDuration == 0)
    }

    // MARK: - Consistency Calculation

    @Test("Consistency is high for identical reps")
    func consistencyHighForIdenticalReps() {
        let reps = (1...5).map { i in
            TestData.makeRepSegment(
                repNumber: i,
                verticalDisplacement: 0.3,
                duration: 2.0
            )
        }

        let metrics = AnalysisMetrics.calculate(from: reps)
        #expect(metrics.consistency == 1.0)
    }

    @Test("Consistency is lower for varied reps")
    func consistencyLowerForVariedReps() {
        let reps = [
            TestData.makeRepSegment(repNumber: 1, verticalDisplacement: 0.2, duration: 1.5),
            TestData.makeRepSegment(repNumber: 2, verticalDisplacement: 0.4, duration: 3.0),
            TestData.makeRepSegment(repNumber: 3, verticalDisplacement: 0.15, duration: 1.0),
        ]

        let metrics = AnalysisMetrics.calculate(from: reps)
        // With highly varied displacement and duration, consistency should be notably below 1.0
        #expect(metrics.consistency < 0.8)
        #expect(metrics.consistency >= 0.0)
    }

    @Test("Consistency is bounded between 0 and 1")
    func consistencyBounds() {
        let reps = [
            TestData.makeRepSegment(repNumber: 1, verticalDisplacement: 0.1, duration: 0.5),
            TestData.makeRepSegment(repNumber: 2, verticalDisplacement: 1.0, duration: 5.0),
        ]

        let metrics = AnalysisMetrics.calculate(from: reps)
        #expect(metrics.consistency >= 0.0)
        #expect(metrics.consistency <= 1.0)
    }

    // MARK: - Codable

    @Test("Codable round-trip preserves all metrics")
    func codableRoundTrip() throws {
        let reps = [
            TestData.makeRepSegment(repNumber: 1),
            TestData.makeRepSegment(repNumber: 2),
        ]
        let original = AnalysisMetrics.calculate(from: reps)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AnalysisMetrics.self, from: data)

        #expect(decoded.peakVelocity == original.peakVelocity)
        #expect(decoded.averageVelocity == original.averageVelocity)
        #expect(decoded.totalVerticalDisplacement == original.totalVerticalDisplacement)
        #expect(decoded.maxHorizontalDrift == original.maxHorizontalDrift)
        #expect(decoded.averageHorizontalDrift == original.averageHorizontalDrift)
        #expect(decoded.consistency == original.consistency)
        #expect(decoded.repCount == original.repCount)
        #expect(decoded.averageRepDuration == original.averageRepDuration)
    }
}
