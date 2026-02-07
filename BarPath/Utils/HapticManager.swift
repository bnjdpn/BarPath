import UIKit

/// Centralized haptic feedback manager for consistent tactile responses across the app.
/// Provides haptic feedback for recording events, analysis completion, exports, and errors.
@MainActor
final class HapticManager: Sendable {

    // MARK: - Singleton

    static let shared = HapticManager()

    // MARK: - Private Properties

    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    // MARK: - Initialization

    private init() {
        impact.prepare()
        notification.prepare()
        selection.prepare()
    }

    // MARK: - Recording Events

    /// Triggers haptic feedback when recording starts.
    func recordingStarted() {
        impact.impactOccurred(intensity: 0.8)
    }

    /// Triggers haptic feedback when recording stops.
    func recordingStopped() {
        impact.impactOccurred(intensity: 1.0)
    }

    /// Triggers haptic feedback when a rep is detected during live tracking.
    func repDetected() {
        selection.selectionChanged()
    }

    // MARK: - Analysis Events

    /// Triggers success haptic feedback when analysis completes successfully.
    func analysisComplete() {
        notification.notificationOccurred(.success)
    }

    /// Triggers success haptic feedback when video export completes.
    func exportComplete() {
        notification.notificationOccurred(.success)
    }

    // MARK: - Error Events

    /// Triggers error haptic feedback when an error occurs.
    func errorOccurred() {
        notification.notificationOccurred(.error)
    }

    // MARK: - UI Interactions

    /// Triggers light haptic feedback for button taps and selections.
    func buttonTap() {
        impact.impactOccurred(intensity: 0.5)
    }

    /// Triggers selection haptic feedback for picker and segmented control changes.
    func selectionChanged() {
        selection.selectionChanged()
    }

    // MARK: - Warning Events

    /// Triggers warning haptic feedback for non-critical warnings.
    func warning() {
        notification.notificationOccurred(.warning)
    }
}
