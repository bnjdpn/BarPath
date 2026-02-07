import Testing
import Foundation
@testable import BarPath

struct OneRMCalculatorTests {

    // MARK: - Edge Cases

    @Test("Empty data returns nil")
    func testEmptyData() {
        let result = OneRMCalculator.calculate(from: [], formula: .vbt)
        #expect(result == nil)
    }

    @Test("Single data point returns nil for VBT")
    func testSingleDataPointVBT() {
        let dataPoints = [(load: 100.0, velocity: 0.5)]
        let result = OneRMCalculator.calculate(from: dataPoints, formula: .vbt)
        #expect(result == nil)
    }

    @Test("Single data point returns result for Epley")
    func testSingleDataPointEpley() {
        let dataPoints = [(load: 100.0, velocity: 5.0)]
        let result = OneRMCalculator.calculate(from: dataPoints, formula: .epley)
        #expect(result != nil)
        #expect(result?.estimatedOneRM ?? 0 > 0)
    }

    @Test("Single data point returns result for Brzycki")
    func testSingleDataPointBrzycki() {
        let dataPoints = [(load: 100.0, velocity: 5.0)]
        let result = OneRMCalculator.calculate(from: dataPoints, formula: .brzycki)
        #expect(result != nil)
        #expect(result?.estimatedOneRM ?? 0 > 0)
    }

    // MARK: - VBT Formula Tests

    @Test("VBT with perfect linear data")
    func testVBTPerfectLinear() {
        let dataPoints = [
            (load: 60.0, velocity: 1.0),
            (load: 80.0, velocity: 0.8),
            (load: 100.0, velocity: 0.6),
            (load: 120.0, velocity: 0.4)
        ]

        let result = OneRMCalculator.calculate(from: dataPoints, formula: .vbt)

        #expect(result != nil)
        #expect(result?.estimatedOneRM ?? 0 > 120.0)
        #expect(result?.confidence ?? 0 > 0.95)
        #expect(result?.trendLinePoints.isEmpty == false)
    }

    @Test("VBT with noisy data")
    func testVBTNoisyData() {
        let dataPoints = [
            (load: 60.0, velocity: 1.02),
            (load: 80.0, velocity: 0.78),
            (load: 100.0, velocity: 0.63),
            (load: 120.0, velocity: 0.41),
            (load: 140.0, velocity: 0.19)
        ]

        let result = OneRMCalculator.calculate(from: dataPoints, formula: .vbt)

        #expect(result != nil)
        #expect(result?.estimatedOneRM ?? 0 > 140.0)
        #expect(result?.confidence ?? 0 > 0.8)
    }

    @Test("VBT with two data points")
    func testVBTTwoPoints() {
        let dataPoints = [
            (load: 100.0, velocity: 0.6),
            (load: 120.0, velocity: 0.4)
        ]

        let result = OneRMCalculator.calculate(from: dataPoints, formula: .vbt)

        #expect(result != nil)
        #expect(result?.estimatedOneRM ?? 0 > 120.0)
        #expect(result?.trendLinePoints.count ?? 0 > 0)
    }

    @Test("VBT trend line covers data range")
    func testVBTTrendLineRange() {
        let dataPoints = [
            (load: 60.0, velocity: 1.0),
            (load: 100.0, velocity: 0.6),
            (load: 140.0, velocity: 0.2)
        ]

        let result = OneRMCalculator.calculate(from: dataPoints, formula: .vbt)

        #expect(result != nil)
        let trendLine = result?.trendLinePoints ?? []
        #expect(trendLine.count > 0)

        let minVelocity = trendLine.map(\.velocity).min() ?? 0
        let maxVelocity = trendLine.map(\.velocity).max() ?? 0

        #expect(minVelocity <= 0.2)
        #expect(maxVelocity >= 1.0)
    }

    // MARK: - Epley Formula Tests

    @Test("Epley formula with known values")
    func testEpleyKnownValues() {
        let dataPoints = [(load: 100.0, velocity: 5.0)]
        let result = OneRMCalculator.calculate(from: dataPoints, formula: .epley)

        #expect(result != nil)

        let expected = 100.0 * (1.0 + 5.0 / 30.0)
        let epsilon = 0.01
        #expect(abs((result?.estimatedOneRM ?? 0) - expected) < epsilon)
    }

    @Test("Epley with multiple data points averages estimates")
    func testEpleyMultiplePoints() {
        let dataPoints = [
            (load: 100.0, velocity: 5.0),
            (load: 90.0, velocity: 6.0),
            (load: 110.0, velocity: 4.0)
        ]

        let result = OneRMCalculator.calculate(from: dataPoints, formula: .epley)

        #expect(result != nil)

        let estimate1 = 100.0 * (1.0 + 5.0 / 30.0)
        let estimate2 = 90.0 * (1.0 + 6.0 / 30.0)
        let estimate3 = 110.0 * (1.0 + 4.0 / 30.0)
        let expected = (estimate1 + estimate2 + estimate3) / 3.0

        let epsilon = 0.01
        #expect(abs((result?.estimatedOneRM ?? 0) - expected) < epsilon)
    }

    @Test("Epley confidence increases with data points")
    func testEpleyConfidence() {
        let onePoint = [(load: 100.0, velocity: 5.0)]
        let fivePoints = [
            (load: 100.0, velocity: 5.0),
            (load: 90.0, velocity: 6.0),
            (load: 110.0, velocity: 4.0),
            (load: 95.0, velocity: 5.5),
            (load: 105.0, velocity: 4.5)
        ]

        let result1 = OneRMCalculator.calculate(from: onePoint, formula: .epley)
        let result5 = OneRMCalculator.calculate(from: fivePoints, formula: .epley)

        #expect((result5?.confidence ?? 0) > (result1?.confidence ?? 0))
        #expect((result5?.confidence ?? 0) >= 1.0)
    }

    @Test("Epley trend line is generated")
    func testEpleyTrendLine() {
        let dataPoints = [(load: 100.0, velocity: 5.0)]
        let result = OneRMCalculator.calculate(from: dataPoints, formula: .epley)

        #expect(result != nil)
        #expect(result?.trendLinePoints.isEmpty == false)
        #expect((result?.trendLinePoints.count ?? 0) > 10)
    }

    // MARK: - Brzycki Formula Tests

    @Test("Brzycki formula with known values")
    func testBrzyckiKnownValues() {
        let dataPoints = [(load: 100.0, velocity: 5.0)]
        let result = OneRMCalculator.calculate(from: dataPoints, formula: .brzycki)

        #expect(result != nil)

        let expected = 100.0 * (36.0 / (37.0 - 5.0))
        let epsilon = 0.01
        #expect(abs((result?.estimatedOneRM ?? 0) - expected) < epsilon)
    }

    @Test("Brzycki with multiple data points averages estimates")
    func testBrzyckiMultiplePoints() {
        let dataPoints = [
            (load: 100.0, velocity: 5.0),
            (load: 90.0, velocity: 6.0),
            (load: 110.0, velocity: 4.0)
        ]

        let result = OneRMCalculator.calculate(from: dataPoints, formula: .brzycki)

        #expect(result != nil)

        let estimate1 = 100.0 * (36.0 / (37.0 - 5.0))
        let estimate2 = 90.0 * (36.0 / (37.0 - 6.0))
        let estimate3 = 110.0 * (36.0 / (37.0 - 4.0))
        let expected = (estimate1 + estimate2 + estimate3) / 3.0

        let epsilon = 0.01
        #expect(abs((result?.estimatedOneRM ?? 0) - expected) < epsilon)
    }

    @Test("Brzycki handles reps >= 37 gracefully")
    func testBrzyckiExtremeReps() {
        let dataPoints = [
            (load: 50.0, velocity: 40.0),
            (load: 100.0, velocity: 5.0)
        ]

        let result = OneRMCalculator.calculate(from: dataPoints, formula: .brzycki)

        #expect(result != nil)
    }

    @Test("Brzycki trend line is generated")
    func testBrzyckiTrendLine() {
        let dataPoints = [(load: 100.0, velocity: 5.0)]
        let result = OneRMCalculator.calculate(from: dataPoints, formula: .brzycki)

        #expect(result != nil)
        #expect(result?.trendLinePoints.isEmpty == false)
        #expect((result?.trendLinePoints.count ?? 0) > 10)
    }

    // MARK: - Extreme Values

    @Test("Handles very large loads")
    func testVeryLargeLoads() {
        let dataPoints = [
            (load: 1000.0, velocity: 0.5),
            (load: 1200.0, velocity: 0.3)
        ]

        let result = OneRMCalculator.calculate(from: dataPoints, formula: .vbt)

        #expect(result != nil)
        #expect(result?.estimatedOneRM ?? 0 > 1200.0)
    }

    @Test("Handles very small velocities")
    func testVerySmallVelocities() {
        let dataPoints = [
            (load: 100.0, velocity: 0.05),
            (load: 120.0, velocity: 0.02)
        ]

        let result = OneRMCalculator.calculate(from: dataPoints, formula: .vbt)

        #expect(result != nil)
        #expect(result?.estimatedOneRM ?? 0 > 0)
    }

    @Test("Handles zero velocity")
    func testZeroVelocity() {
        let dataPoints = [
            (load: 100.0, velocity: 0.0),
            (load: 120.0, velocity: 0.1)
        ]

        let result = OneRMCalculator.calculate(from: dataPoints, formula: .vbt)

        #expect(result != nil)
    }

    @Test("Rejects negative 1RM estimates")
    func testNegativeOneRMRejected() {
        let dataPoints = [
            (load: -50.0, velocity: 1.0),
            (load: -100.0, velocity: 0.5)
        ]

        let result = OneRMCalculator.calculate(from: dataPoints, formula: .vbt)

        #expect(result == nil)
    }

    // MARK: - Confidence Scoring

    @Test("Perfect linear data has high confidence")
    func testPerfectLinearConfidence() {
        let dataPoints = [
            (load: 60.0, velocity: 1.0),
            (load: 80.0, velocity: 0.8),
            (load: 100.0, velocity: 0.6),
            (load: 120.0, velocity: 0.4),
            (load: 140.0, velocity: 0.2)
        ]

        let result = OneRMCalculator.calculate(from: dataPoints, formula: .vbt)

        #expect(result != nil)
        #expect(result?.confidence ?? 0 > 0.99)
    }

    @Test("Noisy data has lower confidence")
    func testNoisyDataConfidence() {
        let noisyDataPoints = [
            (load: 60.0, velocity: 1.2),
            (load: 80.0, velocity: 0.5),
            (load: 100.0, velocity: 0.9),
            (load: 120.0, velocity: 0.3)
        ]

        let result = OneRMCalculator.calculate(from: noisyDataPoints, formula: .vbt)

        #expect(result != nil)
        #expect(result?.confidence ?? 1 < 0.95)
    }

    // MARK: - Sendable Conformance

    @Test("Result is Sendable")
    func testResultSendable() {
        let dataPoints = [(load: 100.0, velocity: 0.5), (load: 120.0, velocity: 0.3)]
        let result = OneRMCalculator.calculate(from: dataPoints, formula: .vbt)

        Task {
            let _ = result
        }
    }
}
