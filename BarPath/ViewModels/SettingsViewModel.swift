import SwiftUI

/// ViewModel for the settings screen, managing user preferences and
/// persisting changes via the data store.
@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Properties

    var settings: AppSettings

    private let persistence: DataStoring

    // MARK: - Initialization

    init(persistence: DataStoring = PersistenceService()) {
        self.persistence = persistence
        self.settings = persistence.loadSettings()
    }

    // MARK: - Recording Settings

    /// Updates the preferred lift type.
    func updatePreferredLiftType(_ liftType: LiftType) {
        settings.preferredLiftType = liftType
        save()
    }

    /// Updates the recording FPS.
    func updateRecordingFPS(_ fps: RecordingFPS) {
        settings.recordingFPS = fps
        save()
    }

    // MARK: - Display Settings

    /// Updates the path color mode.
    func updatePathColor(_ colorOption: PathColorOption) {
        settings.pathColor = colorOption
        save()
    }

    /// Toggles the velocity overlay.
    func updateShowVelocityOverlay(_ show: Bool) {
        settings.showVelocityOverlay = show
        save()
    }

    /// Toggles the drift lines overlay.
    func updateShowDriftLines(_ show: Bool) {
        settings.showDriftLines = show
        save()
    }

    // MARK: - Calibration Settings

    /// Updates the calibration data.
    func updateCalibration(_ calibration: CalibrationData?) {
        settings.calibrationData = calibration
        save()
    }

    // MARK: - Auto-detect Settings

    /// Toggles automatic rep detection.
    func updateAutoDetectReps(_ autoDetect: Bool) {
        settings.autoDetectReps = autoDetect
        save()
    }

    // MARK: - Persistence

    /// Persists the current settings to storage.
    private func save() {
        persistence.saveSettings(settings)
    }
}
