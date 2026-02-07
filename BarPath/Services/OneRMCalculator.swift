import Foundation

/// Calculates one-repetition maximum (1RM) estimates using velocity-based training (VBT) data
/// and traditional repetition-based formulas. Supports linear regression on load-velocity profiles.
struct OneRMCalculator: Sendable {

    // MARK: - Types

    /// Formula used for 1RM estimation
    enum Formula: Sendable {
        /// Epley formula: 1RM = weight × (1 + reps/30)
        case epley
        /// Brzycki formula: 1RM = weight × (36 / (37 - reps))
        case brzycki
        /// Velocity-based training: Linear regression on load-velocity profile
        case vbt
    }

    /// Result of a 1RM calculation
    struct Result: Sendable {
        /// Estimated one-repetition maximum in the same units as input loads
        let estimatedOneRM: Double

        /// Confidence score from 0 (unreliable) to 1 (highly reliable)
        /// Based on R² for VBT, data point count for traditional formulas
        let confidence: Double

        /// Points defining the trend line for visualization
        /// For VBT: linear regression line; for traditional: exponential curve
        let trendLinePoints: [(load: Double, velocity: Double)]
    }

    // MARK: - Public API

    /// Calculates 1RM from velocity-based training data or repetition data.
    ///
    /// - Parameters:
    ///   - dataPoints: Array of (load, velocity) tuples. For traditional formulas,
    ///     velocity represents reps performed (e.g., 5 reps → velocity = 5.0)
    ///   - formula: The calculation method to use (default: VBT)
    /// - Returns: A `Result` with estimated 1RM, confidence, and trend line, or `nil` if insufficient data
    static func calculate(
        from dataPoints: [(load: Double, velocity: Double)],
        formula: Formula = .vbt
    ) -> Result? {
        guard !dataPoints.isEmpty else { return nil }

        switch formula {
        case .epley:
            return calculateEpley(from: dataPoints)
        case .brzycki:
            return calculateBrzycki(from: dataPoints)
        case .vbt:
            return calculateVBT(from: dataPoints)
        }
    }

    // MARK: - Traditional Formulas

    /// Epley formula: 1RM = weight × (1 + reps/30)
    private static func calculateEpley(from dataPoints: [(load: Double, velocity: Double)]) -> Result? {
        guard !dataPoints.isEmpty else { return nil }

        let estimates = dataPoints.map { load, reps in
            load * (1.0 + reps / 30.0)
        }

        let averageOneRM = estimates.reduce(0, +) / Double(estimates.count)
        let confidence = min(1.0, Double(dataPoints.count) / 5.0)

        let trendLine = generateEpleyTrendLine(oneRM: averageOneRM, dataPoints: dataPoints)

        return Result(
            estimatedOneRM: averageOneRM,
            confidence: confidence,
            trendLinePoints: trendLine
        )
    }

    /// Brzycki formula: 1RM = weight × (36 / (37 - reps))
    private static func calculateBrzycki(from dataPoints: [(load: Double, velocity: Double)]) -> Result? {
        guard !dataPoints.isEmpty else { return nil }

        let estimates = dataPoints.compactMap { load, reps -> Double? in
            guard reps < 37 else { return nil }
            return load * (36.0 / (37.0 - reps))
        }

        guard !estimates.isEmpty else { return nil }

        let averageOneRM = estimates.reduce(0, +) / Double(estimates.count)
        let confidence = min(1.0, Double(dataPoints.count) / 5.0)

        let trendLine = generateBrzyckiTrendLine(oneRM: averageOneRM, dataPoints: dataPoints)

        return Result(
            estimatedOneRM: averageOneRM,
            confidence: confidence,
            trendLinePoints: trendLine
        )
    }

    // MARK: - Velocity-Based Training

    /// VBT formula: Linear regression on load-velocity profile.
    /// Extrapolates to the velocity at which load would theoretically be zero (1RM).
    private static func calculateVBT(from dataPoints: [(load: Double, velocity: Double)]) -> Result? {
        guard dataPoints.count >= 2 else { return nil }

        let loads = dataPoints.map(\.load)
        let velocities = dataPoints.map(\.velocity)

        guard let regression = linearRegression(x: velocities, y: loads) else {
            return nil
        }

        let minVelocity = velocities.min() ?? 0
        let estimatedOneRM = regression.slope * minVelocity + regression.intercept

        guard estimatedOneRM > 0 else { return nil }

        let trendLine = generateVBTTrendLine(regression: regression, dataPoints: dataPoints)

        return Result(
            estimatedOneRM: estimatedOneRM,
            confidence: regression.rSquared,
            trendLinePoints: trendLine
        )
    }

    // MARK: - Linear Regression

    private struct LinearRegressionResult: Sendable {
        let slope: Double
        let intercept: Double
        let rSquared: Double
    }

    /// Performs simple linear regression: y = mx + b
    /// Returns slope (m), intercept (b), and R² coefficient of determination
    private static func linearRegression(x: [Double], y: [Double]) -> LinearRegressionResult? {
        guard x.count == y.count, x.count >= 2 else { return nil }

        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        _ = y.map { $0 * $0 }.reduce(0, +)  // sumY2 not needed for current implementation

        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return nil }

        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n

        let meanY = sumY / n
        let ssTotal = y.map { ($0 - meanY) * ($0 - meanY) }.reduce(0.0) { $0 + $1 }
        let ssResidual = zip(x, y).map { xVal, yVal in
            let predicted = slope * xVal + intercept
            return (yVal - predicted) * (yVal - predicted)
        }.reduce(0.0) { $0 + $1 }

        let rSquared = ssTotal > 0 ? max(0, min(1, 1 - ssResidual / ssTotal)) : 0

        return LinearRegressionResult(slope: slope, intercept: intercept, rSquared: rSquared)
    }

    // MARK: - Trend Line Generation

    private static func generateEpleyTrendLine(oneRM: Double, dataPoints: [(load: Double, velocity: Double)]) -> [(load: Double, velocity: Double)] {
        let maxReps = (dataPoints.map(\.velocity).max() ?? 10) * 1.2
        let repsRange = stride(from: 1.0, through: maxReps, by: maxReps / 20.0)

        return repsRange.map { reps in
            let load = oneRM / (1.0 + reps / 30.0)
            return (load: load, velocity: reps)
        }
    }

    private static func generateBrzyckiTrendLine(oneRM: Double, dataPoints: [(load: Double, velocity: Double)]) -> [(load: Double, velocity: Double)] {
        let maxReps = min((dataPoints.map(\.velocity).max() ?? 10) * 1.2, 36.0)
        let repsRange = stride(from: 1.0, through: maxReps, by: maxReps / 20.0)

        return repsRange.map { reps in
            let load = oneRM * (37.0 - reps) / 36.0
            return (load: load, velocity: reps)
        }
    }

    private static func generateVBTTrendLine(regression: LinearRegressionResult, dataPoints: [(load: Double, velocity: Double)]) -> [(load: Double, velocity: Double)] {
        let minVelocity = dataPoints.map(\.velocity).min() ?? 0
        let maxVelocity = dataPoints.map(\.velocity).max() ?? 1

        let velocityRange = stride(from: minVelocity, through: maxVelocity * 1.1, by: (maxVelocity - minVelocity) / 20.0)

        return velocityRange.map { velocity in
            let load = regression.slope * velocity + regression.intercept
            return (load: load, velocity: velocity)
        }
    }
}
