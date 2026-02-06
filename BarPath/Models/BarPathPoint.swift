import Foundation
import CoreGraphics

/// A single tracked point on the barbell path, captured from Vision framework wrist detection.
/// Coordinates are normalized to the video frame (0-1 range).
struct BarPathPoint: Codable, Sendable, Identifiable, Equatable {

    // MARK: - Properties

    let id: UUID
    let x: Double
    let y: Double
    let timestamp: TimeInterval
    let confidence: Float

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
        confidence: Float
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.timestamp = timestamp
        self.confidence = confidence
    }
}
