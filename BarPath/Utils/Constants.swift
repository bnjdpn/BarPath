import Foundation

/// App-wide constants organized by domain.
enum Constants {

    // MARK: - Analysis

    /// Constants related to bar path analysis algorithms.
    enum Analysis {
        /// Number of points on each side used for moving average smoothing.
        static let smoothingWindowSize = 5

        /// Minimum Vision confidence required to accept a wrist detection (0-1).
        static let minimumConfidence: Float = 0.3

        /// Minimum vertical displacement (normalized) to consider a movement as a rep.
        static let minimumRepDisplacement: Double = 0.05
    }

    // MARK: - Recording

    /// Constants related to video recording.
    enum Recording {
        /// Maximum recording duration in seconds.
        static let maxRecordingDuration: TimeInterval = 60.0

        /// Default recording frame rate.
        static let defaultFPS: Double = 60
    }

    // MARK: - Persistence

    /// Constants related to data persistence.
    enum Persistence {
        /// Maximum number of recent analyses to keep in history.
        static let maxRecentAnalyses = 20

        /// Prefix for all UserDefaults keys to avoid collisions.
        static let userDefaultsPrefix = "barpath_"
    }

    // MARK: - Velocity

    /// Velocity thresholds for color coding the bar path (in m/s).
    enum Velocity {
        /// Velocities below this value are considered slow (red zone).
        static let slowThreshold: Double = 0.3

        /// Velocities below this value are considered medium (yellow zone).
        /// Velocities at or above this value are considered fast (green zone).
        static let mediumThreshold: Double = 0.6
    }
}
