import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {

    /// Returns a user-friendly formatted date string (e.g., "Jan 15, 2026").
    var formatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Returns a formatted date string with time (e.g., "Jan 15, 2026 at 3:45 PM").
    var formattedWithTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Double Extensions

extension Double {

    /// Formats the double to a specified number of decimal places.
    ///
    /// - Parameter decimals: The number of decimal places (default: 2).
    /// - Returns: A formatted string representation.
    func formatted(decimals: Int = 2) -> String {
        String(format: "%.\(decimals)f", self)
    }

    /// Formats the value as a velocity string with m/s unit.
    ///
    /// - Returns: A string like "0.45 m/s".
    var formattedVelocity: String {
        "\(formatted(decimals: 2)) m/s"
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {

    /// Formats the time interval as a duration string (mm:ss).
    ///
    /// - Returns: A string like "01:30" for 90 seconds.
    var formattedDuration: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Color Extensions

extension Color {

    // MARK: - Lift Type Colors

    /// Color for squat lift type.
    static let squatColor = Color.blue

    /// Color for bench press lift type.
    static let benchPressColor = Color.red

    /// Color for deadlift lift type.
    static let deadliftColor = Color.orange

    /// Color for overhead press lift type.
    static let overheadPressColor = Color.purple

    /// Color for clean lift type.
    static let cleanColor = Color.green

    /// Color for snatch lift type.
    static let snatchColor = Color.yellow

    /// Color for row lift type.
    static let rowColor = Color.teal

    /// Color for other lift type.
    static let otherLiftColor = Color.gray

    // MARK: - Velocity Gradient Colors

    /// Color representing slow velocity (below slow threshold).
    static let velocitySlow = Color.red

    /// Color representing medium velocity (between slow and fast thresholds).
    static let velocityMedium = Color.yellow

    /// Color representing fast velocity (above fast threshold).
    static let velocityFast = Color.green

    // MARK: - Velocity Color Mapping

    /// Returns a color for a given velocity value based on defined thresholds.
    ///
    /// - Parameter velocity: The velocity in m/s.
    /// - Returns: A color from the velocity gradient (red -> yellow -> green).
    static func forVelocity(_ velocity: Double) -> Color {
        if velocity < Constants.Velocity.slowThreshold {
            return .velocitySlow
        } else if velocity < Constants.Velocity.mediumThreshold {
            return .velocityMedium
        } else {
            return .velocityFast
        }
    }
}

// MARK: - Environment Extensions

/// Environment key for app settings.
private struct AppSettingsKey: EnvironmentKey {
    static let defaultValue = AppSettings.default
}

extension EnvironmentValues {
    /// Access app settings from the environment.
    var appSettings: AppSettings {
        get { self[AppSettingsKey.self] }
        set { self[AppSettingsKey.self] = newValue }
    }
}
