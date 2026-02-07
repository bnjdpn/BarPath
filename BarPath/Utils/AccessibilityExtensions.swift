import SwiftUI

// MARK: - Accessibility Label Extensions

extension View {
    /// Adds a localized accessibility label to the view using a localization key.
    ///
    /// - Parameter localizedKey: The localization key for the accessibility label.
    /// - Returns: A view with the localized accessibility label applied.
    func accessibilityLocalizedLabel(_ localizedKey: String) -> some View {
        self.accessibilityLabel(NSLocalizedString(localizedKey, comment: "Accessibility"))
    }

    /// Adds a localized accessibility hint to the view using a localization key.
    ///
    /// - Parameter localizedKey: The localization key for the accessibility hint.
    /// - Returns: A view with the localized accessibility hint applied.
    func accessibilityLocalizedHint(_ localizedKey: String) -> some View {
        self.accessibilityHint(NSLocalizedString(localizedKey, comment: "Accessibility"))
    }
}

// MARK: - Accessibility Identifier Extensions

extension View {
    /// Adds an accessibility identifier to the view for UI testing.
    ///
    /// - Parameter id: The unique identifier for the view.
    /// - Returns: A view with the accessibility identifier applied.
    func accessibilityId(_ id: String) -> some View {
        self.accessibilityIdentifier(id)
    }
}

// MARK: - Accessibility Value Formatting

extension View {
    /// Formats a percentage value for VoiceOver with localized "percent" suffix.
    ///
    /// - Parameter value: The percentage value (0.0 to 1.0).
    /// - Returns: A view with formatted accessibility value.
    func accessibilityPercentageValue(_ value: Double) -> some View {
        let percentage = Int(value * 100)
        return self.accessibilityValue("\(percentage)%")
    }

    /// Formats a duration value for VoiceOver with localized time units.
    ///
    /// - Parameter seconds: Duration in seconds.
    /// - Returns: A view with formatted accessibility value.
    func accessibilityDurationValue(_ seconds: TimeInterval) -> some View {
        let formatted = String(format: "%.1f seconds", seconds)
        return self.accessibilityValue(formatted)
    }
}
