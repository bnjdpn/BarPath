import Foundation

/// Generates intelligent coaching feedback based on bar path analysis results.
/// All feedback is localized and categorized by severity.
struct CoachingService: Sendable {

    // MARK: - Types

    /// A single coaching tip with localized text and severity level
    struct Tip: Sendable, Identifiable {
        let id: UUID
        let text: String
        let severity: Severity

        init(id: UUID = UUID(), text: String, severity: Severity) {
            self.id = id
            self.text = text
            self.severity = severity
        }
    }

    /// Severity level of a coaching tip
    enum Severity: Sendable {
        case info
        case warning
        case critical
    }

    // MARK: - Constants

    private enum Thresholds {
        static let driftWarningCm: Double = 5.0
        static let driftCriticalCm: Double = 10.0
        static let velocityDropWarning: Double = 0.15
        static let velocityDropCritical: Double = 0.25
        static let consistencyGood: Double = 0.85
        static let consistencyPoor: Double = 0.7
        static let velocityVariationLow: Double = 0.10
    }

    // MARK: - Public API

    /// Generates coaching tips from a bar path analysis.
    ///
    /// - Parameter analysis: The complete analysis to evaluate
    /// - Returns: Array of localized coaching tips ordered by severity (critical, warning, info)
    static func generateTips(for analysis: BarPathAnalysis) -> [Tip] {
        var tips: [Tip] = []

        tips.append(contentsOf: analyzeDrift(analysis))
        tips.append(contentsOf: analyzeFatigue(analysis))
        tips.append(contentsOf: analyzeConsistency(analysis))
        tips.append(contentsOf: analyzeVelocityPattern(analysis))

        return tips.sorted { tip1, tip2 in
            severityRank(tip1.severity) > severityRank(tip2.severity)
        }
    }

    // MARK: - Drift Analysis

    private static func analyzeDrift(_ analysis: BarPathAnalysis) -> [Tip] {
        var tips: [Tip] = []

        let maxDriftCm = analysis.metrics.maxHorizontalDrift * 100
        let avgDriftCm = analysis.metrics.averageHorizontalDrift * 100

        if maxDriftCm >= Thresholds.driftCriticalCm {
            let text = String(
                format: NSLocalizedString("coaching_drift_critical", comment: "Critical horizontal drift warning"),
                maxDriftCm
            )
            tips.append(Tip(text: text, severity: .critical))
        } else if maxDriftCm >= Thresholds.driftWarningCm {
            let text = String(
                format: NSLocalizedString("coaching_drift_warning", comment: "Horizontal drift warning"),
                maxDriftCm
            )
            tips.append(Tip(text: text, severity: .warning))
        } else if avgDriftCm < 2.0 {
            let text = NSLocalizedString("coaching_drift_excellent", comment: "Excellent drift control")
            tips.append(Tip(text: text, severity: .info))
        }

        if analysis.reps.count >= 3 {
            let driftProgression = analyzeDriftProgression(analysis.reps)
            if driftProgression > 0.5 {
                let text = NSLocalizedString("coaching_drift_increasing", comment: "Drift increases with fatigue")
                tips.append(Tip(text: text, severity: .warning))
            }
        }

        return tips
    }

    /// Calculates drift progression: positive means drift increases with each rep
    private static func analyzeDriftProgression(_ reps: [RepSegment]) -> Double {
        guard reps.count >= 3 else { return 0 }

        let drifts = reps.map(\.horizontalDrift)
        let indices = Array(0..<reps.count).map(Double.init)

        guard let regression = simpleLinearRegression(x: indices, y: drifts) else {
            return 0
        }

        return regression.slope
    }

    // MARK: - Fatigue Analysis

    private static func analyzeFatigue(_ analysis: BarPathAnalysis) -> [Tip] {
        var tips: [Tip] = []

        guard analysis.reps.count >= 2 else { return tips }

        let avgVelocity = analysis.metrics.averageVelocity

        for rep in analysis.reps {
            let velocityDrop = (avgVelocity - rep.averageVelocity) / avgVelocity

            if velocityDrop >= Thresholds.velocityDropCritical {
                let percentDrop = velocityDrop * 100
                let text = String(
                    format: NSLocalizedString("coaching_fatigue_critical", comment: "Critical fatigue detected"),
                    rep.repNumber,
                    percentDrop
                )
                tips.append(Tip(text: text, severity: .critical))
            } else if velocityDrop >= Thresholds.velocityDropWarning {
                let percentDrop = velocityDrop * 100
                let text = String(
                    format: NSLocalizedString("coaching_fatigue_warning", comment: "Fatigue warning"),
                    rep.repNumber,
                    percentDrop
                )
                tips.append(Tip(text: text, severity: .warning))
            }
        }

        return tips
    }

    // MARK: - Consistency Analysis

    private static func analyzeConsistency(_ analysis: BarPathAnalysis) -> [Tip] {
        var tips: [Tip] = []

        let consistency = analysis.metrics.consistency

        if consistency >= Thresholds.consistencyGood {
            let percentConsistency = consistency * 100
            let text = String(
                format: NSLocalizedString("coaching_consistency_excellent", comment: "Excellent consistency"),
                percentConsistency
            )
            tips.append(Tip(text: text, severity: .info))
        } else if consistency < Thresholds.consistencyPoor {
            let text = NSLocalizedString("coaching_consistency_poor", comment: "Poor consistency detected")
            tips.append(Tip(text: text, severity: .warning))
        }

        return tips
    }

    // MARK: - Velocity Pattern Analysis

    private static func analyzeVelocityPattern(_ analysis: BarPathAnalysis) -> [Tip] {
        var tips: [Tip] = []

        guard analysis.reps.count >= 3 else { return tips }

        let velocities = analysis.reps.map(\.averageVelocity)
        let avgVelocity = velocities.reduce(0, +) / Double(velocities.count)

        let allWithinRange = velocities.allSatisfy { velocity in
            abs(velocity - avgVelocity) / avgVelocity <= Thresholds.velocityVariationLow
        }

        if allWithinRange {
            let text = NSLocalizedString("coaching_velocity_consistent", comment: "Consistent velocity across reps")
            tips.append(Tip(text: text, severity: .info))
        }

        return tips
    }

    // MARK: - Utilities

    private static func severityRank(_ severity: Severity) -> Int {
        switch severity {
        case .critical: return 3
        case .warning: return 2
        case .info: return 1
        }
    }

    private struct SimpleLinearRegression: Sendable {
        let slope: Double
        let intercept: Double
    }

    private static func simpleLinearRegression(x: [Double], y: [Double]) -> SimpleLinearRegression? {
        guard x.count == y.count, x.count >= 2 else { return nil }

        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)

        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return nil }

        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n

        return SimpleLinearRegression(slope: slope, intercept: intercept)
    }
}
