import Foundation
import CoreGraphics

/// Describes which body joints were used to estimate the barbell position.
enum DetectionSource: String, Codable, Sendable, Equatable {
    /// Both wrists detected; position is their midpoint.
    case bothWrists
    /// Only one wrist detected.
    case singleWrist
    /// Both elbows detected; position is their midpoint (wrists unavailable).
    case bothElbows
    /// Only one elbow detected (wrists unavailable).
    case singleElbow
}

/// A single tracked point on the barbell path, captured from Vision framework pose detection.
/// Coordinates are normalized to the video frame (0-1 range).
struct BarPathPoint: Codable, Sendable, Identifiable, Equatable {

    // MARK: - Properties

    let id: UUID
    let x: Double
    let y: Double
    let timestamp: TimeInterval
    let confidence: Float
    let detectionSource: DetectionSource

    // MARK: - Computed Properties

    /// Converts the normalized coordinates to a `CGPoint` suitable for drawing.
    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        x: Double,
        y: Double,
        timestamp: TimeInterval,
        confidence: Float,
        detectionSource: DetectionSource = .singleWrist
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.timestamp = timestamp
        self.confidence = confidence
        self.detectionSource = detectionSource
    }
}
