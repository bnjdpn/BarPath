import Vision
import CoreMedia

/// Protocol abstracting pose detection from video frames.
/// Enables dependency injection and testability by decoupling the detection
/// implementation from consumers.
protocol PoseDetecting: Sendable {

    /// Detects a human body pose in the given pixel buffer and extracts the barbell position.
    ///
    /// - Parameters:
    ///   - pixelBuffer: The video frame to analyze.
    ///   - timestamp: The presentation timestamp of the frame in seconds.
    /// - Returns: A `BarPathPoint` representing the estimated barbell position, or `nil` if
    ///   no pose was detected with sufficient confidence.
    func detectPose(in pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) async throws -> BarPathPoint?
}
