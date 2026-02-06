import Foundation

/// Recording frame rate options.
enum RecordingFPS: Int, Codable, Sendable, CaseIterable {
    case thirty = 30
    case sixty = 60

    var displayName: String {
        switch self {
        case .thirty:
            return NSLocalizedString("recording_fps_30", comment: "30 FPS recording option")
        case .sixty:
            return NSLocalizedString("recording_fps_60", comment: "60 FPS recording option")
        }
    }
}

/// Determines how the bar path line is colored in the overlay.
enum PathColorOption: String, Codable, Sendable, CaseIterable {
    /// Color mapped to instantaneous velocity (e.g., slow = red, fast = green).
    case velocity
    /// A single fixed color for the entire path.
    case fixed
    /// Color indicates eccentric vs. concentric phase.
    case phase

    var displayName: String {
        switch self {
        case .velocity:
            return NSLocalizedString(
                "path_color_velocity",
                comment: "Color path by velocity"
            )
        case .fixed:
            return NSLocalizedString(
                "path_color_fixed",
                comment: "Single fixed color path"
            )
        case .phase:
            return NSLocalizedString(
                "path_color_phase",
                comment: "Color path by lift phase"
            )
        }
    }
}

/// User-configurable application settings, persisted across sessions.
struct AppSettings: Codable, Sendable {

    // MARK: - Properties

    var preferredLiftType: LiftType
    var calibrationData: CalibrationData?
    var showVelocityOverlay: Bool
    var showDriftLines: Bool
    var autoDetectReps: Bool
    var recordingFPS: RecordingFPS
    var pathColor: PathColorOption

    // MARK: - Initialization

    init(
        preferredLiftType: LiftType = .squat,
        calibrationData: CalibrationData? = nil,
        showVelocityOverlay: Bool = true,
        showDriftLines: Bool = true,
        autoDetectReps: Bool = true,
        recordingFPS: RecordingFPS = .sixty,
        pathColor: PathColorOption = .velocity
    ) {
        self.preferredLiftType = preferredLiftType
        self.calibrationData = calibrationData
        self.showVelocityOverlay = showVelocityOverlay
        self.showDriftLines = showDriftLines
        self.autoDetectReps = autoDetectReps
        self.recordingFPS = recordingFPS
        self.pathColor = pathColor
    }

    // MARK: - Defaults

    /// Returns the default application settings.
    static let `default` = AppSettings()
}
