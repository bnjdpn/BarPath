import Foundation
import Vision

/// Detects human body poses in video frames using the Vision framework and extracts
/// the estimated barbell position from wrist joint locations.
///
/// The service prefers the right wrist joint but falls back to the left wrist when
/// the left wrist has higher detection confidence. A minimum confidence threshold
/// filters out unreliable detections.
final class PoseDetectionService: PoseDetecting {

    // MARK: - Constants

    /// Minimum joint confidence required to accept a detection.
    private let minimumConfidence: Float = 0.3

    // MARK: - PoseDetecting

    func detectPose(in pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) async throws -> BarPathPoint? {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        try handler.perform([request])

        guard let observation = request.results?.first else {
            return nil
        }

        return try extractBarPosition(from: observation, timestamp: timestamp)
    }

    // MARK: - Private

    /// Extracts the best wrist position from a body pose observation.
    ///
    /// Chooses the wrist with the highest confidence, provided it meets the minimum
    /// confidence threshold. Vision uses a bottom-left origin coordinate system, so
    /// the Y coordinate is flipped to match a top-left origin (standard for UI rendering).
    ///
    /// - Parameters:
    ///   - observation: The detected human body pose.
    ///   - timestamp: The frame timestamp in seconds.
    /// - Returns: A `BarPathPoint` for the selected wrist, or `nil` if neither wrist
    ///   meets the confidence threshold.
    private func extractBarPosition(
        from observation: VNHumanBodyPoseObservation,
        timestamp: TimeInterval
    ) throws -> BarPathPoint? {
        let rightWrist = try? observation.recognizedPoint(.rightWrist)
        let leftWrist = try? observation.recognizedPoint(.leftWrist)

        let rightConfidence = rightWrist?.confidence ?? 0
        let leftConfidence = leftWrist?.confidence ?? 0

        // Select the wrist with the higher confidence.
        let selectedPoint: VNRecognizedPoint?
        if rightConfidence >= leftConfidence {
            selectedPoint = rightWrist
        } else {
            selectedPoint = leftWrist
        }

        guard let point = selectedPoint, point.confidence >= minimumConfidence else {
            return nil
        }

        // Vision framework uses bottom-left origin; flip Y for top-left origin.
        let flippedY = 1.0 - point.location.y

        return BarPathPoint(
            x: Double(point.location.x),
            y: Double(flippedY),
            timestamp: timestamp,
            confidence: point.confidence
        )
    }
}
