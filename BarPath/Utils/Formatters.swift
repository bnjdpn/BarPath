import Foundation

/// Centralized formatting utilities for displaying analysis values consistently
/// across the app.
enum Formatters {

    // MARK: - Velocity

    /// Formats a velocity value with unit.
    ///
    /// - Parameter value: The velocity in m/s.
    /// - Returns: A string like "0.45 m/s".
    static func velocityString(_ value: Double) -> String {
        String(format: "%.2f m/s", value)
    }

    // MARK: - Displacement

    /// Formats a displacement value with unit.
    ///
    /// - Parameter value: The displacement in meters.
    /// - Returns: A string like "0.82 m".
    static func displacementString(_ value: Double) -> String {
        String(format: "%.2f m", value)
    }

    // MARK: - Drift

    /// Formats a horizontal drift value in centimeters.
    ///
    /// - Parameter value: The drift in meters.
    /// - Returns: A string like "3.2 cm".
    static func driftString(_ value: Double) -> String {
        let centimeters = value * 100
        return String(format: "%.1f cm", centimeters)
    }

    // MARK: - Duration

    /// Formats a time interval as a duration string.
    ///
    /// - Parameter value: The duration in seconds.
    /// - Returns: A string like "01:30" for 90 seconds.
    static func durationString(_ value: TimeInterval) -> String {
        let totalSeconds = Int(value)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Consistency

    /// Formats a consistency score as a percentage.
    ///
    /// - Parameter value: The consistency score (0-1).
    /// - Returns: A string like "87%".
    static func consistencyString(_ value: Double) -> String {
        let percentage = Int(round(value * 100))
        return "\(percentage)%"
    }
}
