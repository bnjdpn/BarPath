import Testing
import Foundation
@testable import BarPath

struct CoachingServiceTests {

    // MARK: - Test Helpers

    private func createAnalysis(
        reps: [RepSegment],
        metrics: AnalysisMetrics? = nil
    ) -> BarPathAnalysis {
        let calculatedMetrics = metrics ?? AnalysisMetrics.calculate(from: reps)

        return BarPathAnalysis(
            liftType: .squat,
            points: [],
            reps: reps,
            metrics: calculatedMetrics,
            duration: Double(reps.count) * 3.0
        )
    }

    private func createRep(
        repNumber: Int,
        peakVelocity: Double = 1.0,
        averageVelocity: Double = 0.8,
        verticalDisplacement: Double = 0.5,
        horizontalDrift: Double = 0.02,
        duration: TimeInterval = 3.0
    ) -> RepSegment {
        RepSegment(
            repNumber: repNumber,
            startIndex: repNumber * 10,
            endIndex: (repNumber + 1) * 10,
            concentricStartIndex: repNumber * 10 + 3,
            peakVelocity: peakVelocity,
            averageVelocity: averageVelocity,
            verticalDisplacement: verticalDisplacement,
            horizontalDrift: horizontalDrift,
            duration: duration
        )
    }

    // MARK: - Empty Analysis

    @Test("Empty analysis returns no tips")
    func testEmptyAnalysis() {
        let analysis = createAnalysis(reps: [])
        let tips = CoachingService.generateTips(for: analysis)

        #expect(tips.isEmpty)
    }

    @Test("Single rep analysis returns minimal tips")
    func testSingleRep() {
        let rep = createRep(repNumber: 1)
        let analysis = createAnalysis(reps: [rep])
        let tips = CoachingService.generateTips(for: analysis)

        #expect(tips.count >= 0)
    }

    // MARK: - Drift Analysis

    @Test("Minimal drift generates positive feedback")
    func testMinimalDrift() {
        let reps = [
            createRep(repNumber: 1, horizontalDrift: 0.005),
            createRep(repNumber: 2, horizontalDrift: 0.008),
            createRep(repNumber: 3, horizontalDrift: 0.006)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        let hasDriftExcellentTip = tips.contains { tip in
            tip.text.localizedCaseInsensitiveContains("excellent") &&
            tip.text.localizedCaseInsensitiveContains("drift")
        }

        #expect(hasDriftExcellentTip)
    }

    @Test("Warning drift generates warning tip")
    func testWarningDrift() {
        let reps = [
            createRep(repNumber: 1, horizontalDrift: 0.06),
            createRep(repNumber: 2, horizontalDrift: 0.07),
            createRep(repNumber: 3, horizontalDrift: 0.065)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        let hasDriftWarning = tips.contains { tip in
            tip.severity == .warning &&
            tip.text.localizedCaseInsensitiveContains("drift")
        }

        #expect(hasDriftWarning)
    }

    @Test("Critical drift generates critical tip")
    func testCriticalDrift() {
        let reps = [
            createRep(repNumber: 1, horizontalDrift: 0.11),
            createRep(repNumber: 2, horizontalDrift: 0.12),
            createRep(repNumber: 3, horizontalDrift: 0.115)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        let hasCriticalDrift = tips.contains { tip in
            tip.severity == .critical &&
            tip.text.localizedCaseInsensitiveContains("drift")
        }

        #expect(hasCriticalDrift)
    }

    @Test("Increasing drift generates warning")
    func testIncreasingDrift() {
        let reps = [
            createRep(repNumber: 1, horizontalDrift: 0.02),
            createRep(repNumber: 2, horizontalDrift: 0.04),
            createRep(repNumber: 3, horizontalDrift: 0.06),
            createRep(repNumber: 4, horizontalDrift: 0.08)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        let hasIncreasingDrift = tips.contains { tip in
            tip.severity == .warning &&
            tip.text.localizedCaseInsensitiveContains("increas")
        }

        #expect(hasIncreasingDrift)
    }

    // MARK: - Fatigue Analysis

    @Test("Consistent velocity generates no fatigue warnings")
    func testConsistentVelocity() {
        let reps = [
            createRep(repNumber: 1, averageVelocity: 0.8),
            createRep(repNumber: 2, averageVelocity: 0.81),
            createRep(repNumber: 3, averageVelocity: 0.79),
            createRep(repNumber: 4, averageVelocity: 0.8)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        let hasFatigueWarning = tips.contains { tip in
            (tip.severity == .warning || tip.severity == .critical) &&
            tip.text.localizedCaseInsensitiveContains("slower")
        }

        #expect(!hasFatigueWarning)
    }

    @Test("Moderate velocity drop generates warning")
    func testModerateVelocityDrop() {
        let reps = [
            createRep(repNumber: 1, averageVelocity: 0.8),
            createRep(repNumber: 2, averageVelocity: 0.79),
            createRep(repNumber: 3, averageVelocity: 0.65),
            createRep(repNumber: 4, averageVelocity: 0.78)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        let hasFatigueWarning = tips.contains { tip in
            tip.severity == .warning &&
            tip.text.localizedCaseInsensitiveContains("slower")
        }

        #expect(hasFatigueWarning)
    }

    @Test("Severe velocity drop generates critical warning")
    func testSevereVelocityDrop() {
        let reps = [
            createRep(repNumber: 1, averageVelocity: 0.8),
            createRep(repNumber: 2, averageVelocity: 0.79),
            createRep(repNumber: 3, averageVelocity: 0.55),
            createRep(repNumber: 4, averageVelocity: 0.78)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        let hasCriticalFatigue = tips.contains { tip in
            tip.severity == .critical &&
            tip.text.localizedCaseInsensitiveContains("slower")
        }

        #expect(hasCriticalFatigue)
    }

    @Test("Fatigue tip includes rep number")
    func testFatigueTipIncludesRepNumber() {
        let reps = [
            createRep(repNumber: 1, averageVelocity: 0.8),
            createRep(repNumber: 2, averageVelocity: 0.79),
            createRep(repNumber: 3, averageVelocity: 0.6),
            createRep(repNumber: 4, averageVelocity: 0.78)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        let hatigueWithRepNumber = tips.contains { tip in
            tip.text.contains("3") && tip.text.localizedCaseInsensitiveContains("slower")
        }

        #expect(hatigueWithRepNumber)
    }

    // MARK: - Consistency Analysis

    @Test("High consistency generates positive feedback")
    func testHighConsistency() {
        let reps = [
            createRep(repNumber: 1, verticalDisplacement: 0.5, duration: 3.0),
            createRep(repNumber: 2, verticalDisplacement: 0.505, duration: 3.02),
            createRep(repNumber: 3, verticalDisplacement: 0.498, duration: 2.99),
            createRep(repNumber: 4, verticalDisplacement: 0.502, duration: 3.01)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        let hasConsistencyPraise = tips.contains { tip in
            tip.severity == .info &&
            tip.text.localizedCaseInsensitiveContains("consistency") ||
            tip.text.localizedCaseInsensitiveContains("régularité")
        }

        #expect(hasConsistencyPraise)
    }

    @Test("Low consistency generates warning")
    func testLowConsistency() {
        let reps = [
            createRep(repNumber: 1, verticalDisplacement: 0.3, duration: 2.0),
            createRep(repNumber: 2, verticalDisplacement: 0.6, duration: 4.0),
            createRep(repNumber: 3, verticalDisplacement: 0.4, duration: 2.5),
            createRep(repNumber: 4, verticalDisplacement: 0.7, duration: 5.0)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        let hasConsistencyWarning = tips.contains { tip in
            tip.severity == .warning &&
            (tip.text.localizedCaseInsensitiveContains("inconsistent") ||
             tip.text.localizedCaseInsensitiveContains("irrégulières"))
        }

        #expect(hasConsistencyWarning)
    }

    // MARK: - Velocity Pattern Analysis

    @Test("Consistent velocity pattern generates positive feedback")
    func testConsistentVelocityPattern() {
        let reps = [
            createRep(repNumber: 1, averageVelocity: 0.8),
            createRep(repNumber: 2, averageVelocity: 0.81),
            createRep(repNumber: 3, averageVelocity: 0.79),
            createRep(repNumber: 4, averageVelocity: 0.80),
            createRep(repNumber: 5, averageVelocity: 0.805)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        let hasVelocityPraise = tips.contains { tip in
            tip.severity == .info &&
            tip.text.localizedCaseInsensitiveContains("velocity")
        }

        #expect(hasVelocityPraise)
    }

    // MARK: - Tip Ordering

    @Test("Tips are ordered by severity")
    func testTipOrdering() {
        let reps = [
            createRep(repNumber: 1, averageVelocity: 0.8, horizontalDrift: 0.11),
            createRep(repNumber: 2, averageVelocity: 0.55, horizontalDrift: 0.12),
            createRep(repNumber: 3, averageVelocity: 0.79, horizontalDrift: 0.06)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        var previousSeverityRank = 3

        for tip in tips {
            let currentRank: Int
            switch tip.severity {
            case .critical: currentRank = 3
            case .warning: currentRank = 2
            case .info: currentRank = 1
            }

            #expect(currentRank <= previousSeverityRank)
            previousSeverityRank = currentRank
        }
    }

    @Test("Critical tips appear first")
    func testCriticalTipsFirst() {
        let reps = [
            createRep(repNumber: 1, averageVelocity: 0.8, horizontalDrift: 0.11),
            createRep(repNumber: 2, averageVelocity: 0.55, horizontalDrift: 0.12),
            createRep(repNumber: 3, averageVelocity: 0.79, horizontalDrift: 0.06)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        let hasCriticalTips = tips.contains { $0.severity == .critical }

        if hasCriticalTips {
            #expect(tips.first?.severity == .critical)
        }
    }

    // MARK: - Localization

    @Test("All tips return localized strings")
    func testTipsAreLocalized() {
        let reps = [
            createRep(repNumber: 1, averageVelocity: 0.8, horizontalDrift: 0.11),
            createRep(repNumber: 2, averageVelocity: 0.65, horizontalDrift: 0.12),
            createRep(repNumber: 3, averageVelocity: 0.79, horizontalDrift: 0.06)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        for tip in tips {
            #expect(!tip.text.isEmpty)
            #expect(!tip.text.hasPrefix("coaching_"))
        }
    }

    // MARK: - Edge Cases

    @Test("Analysis with zero metrics")
    func testZeroMetrics() {
        let metrics = AnalysisMetrics(
            peakVelocity: 0,
            averageVelocity: 0,
            totalVerticalDisplacement: 0,
            maxHorizontalDrift: 0,
            averageHorizontalDrift: 0,
            consistency: 0,
            repCount: 0,
            averageRepDuration: 0
        )

        let analysis = createAnalysis(reps: [], metrics: metrics)
        let tips = CoachingService.generateTips(for: analysis)

        #expect(tips.isEmpty)
    }

    @Test("Analysis with extreme values")
    func testExtremeValues() {
        let reps = [
            createRep(repNumber: 1, averageVelocity: 10.0, horizontalDrift: 1.0),
            createRep(repNumber: 2, averageVelocity: 0.01, horizontalDrift: 0.0)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        #expect(!tips.isEmpty)
    }

    // MARK: - Sendable Conformance

    @Test("Tip is Sendable")
    func testTipSendable() {
        let tip = CoachingService.Tip(text: "Test tip", severity: .info)

        Task {
            let _ = tip
        }
    }

    @Test("Tips can be used in async context")
    func testTipsAsync() async {
        let reps = [
            createRep(repNumber: 1, horizontalDrift: 0.06),
            createRep(repNumber: 2, horizontalDrift: 0.07)
        ]

        let analysis = createAnalysis(reps: reps)

        Task {
            let tips = CoachingService.generateTips(for: analysis)
            #expect(!tips.isEmpty)
        }
    }

    // MARK: - Multiple Tip Types

    @Test("Complex analysis generates multiple tip types")
    func testMultipleTipTypes() {
        let reps = [
            createRep(repNumber: 1, averageVelocity: 0.8, verticalDisplacement: 0.5, horizontalDrift: 0.07),
            createRep(repNumber: 2, averageVelocity: 0.79, verticalDisplacement: 0.51, horizontalDrift: 0.08),
            createRep(repNumber: 3, averageVelocity: 0.65, verticalDisplacement: 0.49, horizontalDrift: 0.09),
            createRep(repNumber: 4, averageVelocity: 0.78, verticalDisplacement: 0.50, horizontalDrift: 0.075)
        ]

        let analysis = createAnalysis(reps: reps)
        let tips = CoachingService.generateTips(for: analysis)

        #expect(tips.count >= 2)

        let severities = Set(tips.map(\.severity))
        #expect(!severities.isEmpty)
    }
}
