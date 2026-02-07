import Foundation
import Vision
import UIKit

/// A lightweight 2D Kalman filter for smoothing tracked positions.
///
/// Maintains a state vector [x, y, vx, vy] representing position and velocity.
/// The filter predicts the next position based on a constant-velocity model and
/// corrects the prediction using incoming measurements. This reduces frame-to-frame
/// jitter in detected barbell positions.
struct KalmanFilter2D: Sendable {

    // MARK: - State

    /// Estimated X position.
    private(set) var x: Double

    /// Estimated Y position.
    private(set) var y: Double

    /// Estimated X velocity (change per second).
    private(set) var vx: Double

    /// Estimated Y velocity (change per second).
    private(set) var vy: Double

    /// Uncertainty in the X position estimate.
    private var px: Double

    /// Uncertainty in the Y position estimate.
    private var py: Double

    /// Uncertainty in the X velocity estimate.
    private var pvx: Double

    /// Uncertainty in the Y velocity estimate.
    private var pvy: Double

    /// Timestamp of the last update, used to compute time deltas.
    private var lastTimestamp: TimeInterval?

    // MARK: - Configuration

    /// Process noise per second squared. Higher values let the filter react faster
    /// to changes but produce noisier output.
    let processNoise: Double

    /// Measurement noise. Higher values make the filter trust measurements less,
    /// producing smoother but more delayed output.
    let measurementNoise: Double

    // MARK: - Initialization

    /// Creates a new Kalman filter with configurable noise parameters.
    ///
    /// - Parameters:
    ///   - processNoise: Process noise variance per second squared. Default 0.001.
    ///   - measurementNoise: Measurement noise variance. Default 0.01.
    init(processNoise: Double = 0.001, measurementNoise: Double = 0.01) {
        self.processNoise = processNoise
        self.measurementNoise = measurementNoise
        self.x = 0
        self.y = 0
        self.vx = 0
        self.vy = 0
        self.px = 1.0
        self.py = 1.0
        self.pvx = 1.0
        self.pvy = 1.0
        self.lastTimestamp = nil
    }

    // MARK: - Public API

    /// Whether the filter has been initialized with at least one measurement.
    var isInitialized: Bool {
        lastTimestamp != nil
    }

    /// The predicted position based on the current state, useful for computing
    /// quality scores before the update step.
    var predictedPosition: (x: Double, y: Double) {
        (x: x, y: y)
    }

    /// Updates the filter with a new measurement and returns the filtered position.
    ///
    /// On the first call, the filter initializes directly to the measurement. On
    /// subsequent calls, it runs a predict-then-update cycle using the elapsed time.
    ///
    /// - Parameters:
    ///   - measuredX: The measured X position (normalized 0-1).
    ///   - measuredY: The measured Y position (normalized 0-1).
    ///   - timestamp: The measurement timestamp in seconds.
    /// - Returns: The filtered (x, y) position.
    mutating func update(measuredX: Double, measuredY: Double, timestamp: TimeInterval) -> (x: Double, y: Double) {
        guard let lastTime = lastTimestamp else {
            // First measurement: initialize state directly.
            x = measuredX
            y = measuredY
            vx = 0
            vy = 0
            px = measurementNoise
            py = measurementNoise
            pvx = 1.0
            pvy = 1.0
            lastTimestamp = timestamp
            return (x: x, y: y)
        }

        let dt = max(timestamp - lastTime, 0.001)
        lastTimestamp = timestamp

        // --- Predict Step ---
        let predictedX = x + vx * dt
        let predictedY = y + vy * dt

        let processVariance = processNoise * dt * dt
        let predictedPx = px + pvx * dt * dt + processVariance
        let predictedPy = py + pvy * dt * dt + processVariance
        let predictedPvx = pvx + processVariance
        let predictedPvy = pvy + processVariance

        // --- Update Step ---
        let kalmanGainX = predictedPx / (predictedPx + measurementNoise)
        let kalmanGainY = predictedPy / (predictedPy + measurementNoise)

        let innovationX = measuredX - predictedX
        let innovationY = measuredY - predictedY

        x = predictedX + kalmanGainX * innovationX
        y = predictedY + kalmanGainY * innovationY

        // Update velocity estimates based on innovation.
        let velocityGainX = predictedPvx * dt / (predictedPx + measurementNoise)
        let velocityGainY = predictedPvy * dt / (predictedPy + measurementNoise)

        vx += velocityGainX * innovationX
        vy += velocityGainY * innovationY

        // Update uncertainties.
        px = (1.0 - kalmanGainX) * predictedPx
        py = (1.0 - kalmanGainY) * predictedPy
        pvx = predictedPvx - velocityGainX * dt * predictedPvx
        pvy = predictedPvy - velocityGainY * dt * predictedPvy

        return (x: x, y: y)
    }

    /// Resets the filter to its uninitialized state.
    mutating func reset() {
        x = 0
        y = 0
        vx = 0
        vy = 0
        px = 1.0
        py = 1.0
        pvx = 1.0
        pvy = 1.0
        lastTimestamp = nil
    }
}

/// Describes the detected orientation of the video frame.
enum FrameOrientation: Sendable {
    case portrait
    case landscapeLeft
    case landscapeRight
    case portraitUpsideDown
}

/// Detects human body poses in video frames using the Vision framework and extracts
/// the estimated barbell position from joint locations.
///
/// Detection strategy (in priority order):
/// 1. Both wrists detected -> midpoint (best barbell approximation)
/// 2. Single wrist detected -> that wrist position
/// 3. Both elbows detected -> midpoint with reduced confidence
/// 4. Single elbow detected -> that elbow position with reduced confidence
///
/// A lightweight 2D Kalman filter smooths position estimates frame-to-frame,
/// and a quality score rates each detection based on confidence, body part
/// visibility, and consistency with the predicted position.
final class PoseDetectionService: PoseDetecting, @unchecked Sendable {

    // MARK: - Constants

    /// Minimum joint confidence required to accept a detection.
    private let minimumConfidence: Float = Constants.Analysis.minimumConfidence

    /// Confidence multiplier applied when falling back to elbow joints.
    private let elbowConfidenceModifier: Float = 0.7

    /// Maximum normalized distance between measurement and prediction before
    /// the consistency component of the quality score drops to zero.
    private let maxPredictionDeviation: Double = 0.15

    // MARK: - Mutable State

    /// Kalman filter for smoothing tracked positions.
    private var kalmanFilter = KalmanFilter2D()

    /// The current frame orientation used for coordinate transformation.
    private var frameOrientation: FrameOrientation = .portrait

    // MARK: - Configuration

    /// Sets the frame orientation for coordinate transformations.
    ///
    /// Call this when the device orientation changes so that Vision's bottom-left
    /// coordinate system is correctly mapped for the current orientation.
    ///
    /// - Parameter orientation: The current frame orientation.
    func setFrameOrientation(_ orientation: FrameOrientation) {
        frameOrientation = orientation
    }

    /// Detects the current device orientation and updates the frame orientation.
    ///
    /// Reads `UIDevice.current.orientation` and maps it to a `FrameOrientation`.
    @MainActor
    func updateOrientationFromDevice() {
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .portrait:
            frameOrientation = .portrait
        case .landscapeLeft:
            frameOrientation = .landscapeLeft
        case .landscapeRight:
            frameOrientation = .landscapeRight
        case .portraitUpsideDown:
            frameOrientation = .portraitUpsideDown
        default:
            // Keep current orientation for face-up, face-down, or unknown.
            break
        }
    }

    /// Resets the Kalman filter state. Call when starting a new recording session.
    func resetFilter() {
        kalmanFilter.reset()
    }

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

    // MARK: - Private: Joint Extraction

    /// Represents a raw joint detection result before coordinate transformation.
    private struct JointDetection {
        let x: Double
        let y: Double
        let confidence: Float
        let source: DetectionSource
    }

    /// Extracts the best barbell position estimate from a body pose observation.
    ///
    /// Tries wrists first (midpoint if both available), then falls back to elbows.
    /// The result is smoothed through a Kalman filter and scored for quality.
    ///
    /// - Parameters:
    ///   - observation: The detected human body pose.
    ///   - timestamp: The frame timestamp in seconds.
    /// - Returns: A `BarPathPoint` for the estimated barbell position, or `nil` if
    ///   no joints meet the confidence threshold.
    private func extractBarPosition(
        from observation: VNHumanBodyPoseObservation,
        timestamp: TimeInterval
    ) throws -> BarPathPoint? {
        // Attempt wrist detection first, then fall back to elbows.
        guard let detection = try detectFromWrists(observation)
                ?? detectFromElbows(observation) else {
            return nil
        }

        // Transform coordinates based on current frame orientation.
        let transformed = transformCoordinates(x: detection.x, y: detection.y)

        // Apply Kalman filter for smoothing.
        let filtered = kalmanFilter.update(
            measuredX: transformed.x,
            measuredY: transformed.y,
            timestamp: timestamp
        )

        // Calculate quality score.
        let visibleJointCount = countVisibleJoints(in: observation)
        let quality = calculateQualityScore(
            rawConfidence: detection.confidence,
            visibleJointCount: visibleJointCount,
            measuredX: transformed.x,
            measuredY: transformed.y
        )

        return BarPathPoint(
            x: filtered.x,
            y: filtered.y,
            timestamp: timestamp,
            confidence: quality,
            detectionSource: detection.source
        )
    }

    /// Attempts to detect barbell position from wrist joints.
    ///
    /// - Parameter observation: The body pose observation.
    /// - Returns: A `JointDetection` if at least one wrist meets the confidence threshold.
    private func detectFromWrists(
        _ observation: VNHumanBodyPoseObservation
    ) throws -> JointDetection? {
        let rightWrist = try? observation.recognizedPoint(.rightWrist)
        let leftWrist = try? observation.recognizedPoint(.leftWrist)

        let rightConf = rightWrist?.confidence ?? 0
        let leftConf = leftWrist?.confidence ?? 0

        let rightValid = rightConf >= minimumConfidence
        let leftValid = leftConf >= minimumConfidence

        if rightValid, leftValid,
           let right = rightWrist, let left = leftWrist {
            // Both wrists detected: use midpoint for best barbell approximation.
            let midX = (Double(right.location.x) + Double(left.location.x)) / 2.0
            let midY = (Double(right.location.y) + Double(left.location.y)) / 2.0
            let avgConfidence = (rightConf + leftConf) / 2.0
            return JointDetection(x: midX, y: midY, confidence: avgConfidence, source: .bothWrists)
        }

        if rightValid, let right = rightWrist {
            return JointDetection(
                x: Double(right.location.x),
                y: Double(right.location.y),
                confidence: rightConf,
                source: .singleWrist
            )
        }

        if leftValid, let left = leftWrist {
            return JointDetection(
                x: Double(left.location.x),
                y: Double(left.location.y),
                confidence: leftConf,
                source: .singleWrist
            )
        }

        return nil
    }

    /// Attempts to detect barbell position from elbow joints as a fallback.
    ///
    /// Applies a confidence modifier since elbows are less precise than wrists
    /// for tracking barbell position.
    ///
    /// - Parameter observation: The body pose observation.
    /// - Returns: A `JointDetection` if at least one elbow meets the confidence threshold.
    private func detectFromElbows(
        _ observation: VNHumanBodyPoseObservation
    ) throws -> JointDetection? {
        let rightElbow = try? observation.recognizedPoint(.rightElbow)
        let leftElbow = try? observation.recognizedPoint(.leftElbow)

        let rightConf = rightElbow?.confidence ?? 0
        let leftConf = leftElbow?.confidence ?? 0

        let rightValid = rightConf >= minimumConfidence
        let leftValid = leftConf >= minimumConfidence

        if rightValid, leftValid,
           let right = rightElbow, let left = leftElbow {
            let midX = (Double(right.location.x) + Double(left.location.x)) / 2.0
            let midY = (Double(right.location.y) + Double(left.location.y)) / 2.0
            let avgConfidence = (rightConf + leftConf) / 2.0 * elbowConfidenceModifier
            return JointDetection(x: midX, y: midY, confidence: avgConfidence, source: .bothElbows)
        }

        if rightValid, let right = rightElbow {
            return JointDetection(
                x: Double(right.location.x),
                y: Double(right.location.y),
                confidence: rightConf * elbowConfidenceModifier,
                source: .singleElbow
            )
        }

        if leftValid, let left = leftElbow {
            return JointDetection(
                x: Double(left.location.x),
                y: Double(left.location.y),
                confidence: leftConf * elbowConfidenceModifier,
                source: .singleElbow
            )
        }

        return nil
    }

    // MARK: - Private: Coordinate Transformation

    /// Transforms Vision coordinates (bottom-left origin) to the appropriate
    /// coordinate system based on the current frame orientation.
    ///
    /// - Parameters:
    ///   - x: The X position in Vision coordinates (0-1).
    ///   - y: The Y position in Vision coordinates (0-1).
    /// - Returns: The transformed (x, y) in top-left origin coordinates.
    private func transformCoordinates(x: Double, y: Double) -> (x: Double, y: Double) {
        switch frameOrientation {
        case .portrait:
            // Vision bottom-left -> UI top-left: flip Y.
            return (x: x, y: 1.0 - y)
        case .landscapeLeft:
            // Device rotated left: swap axes and flip.
            return (x: y, y: x)
        case .landscapeRight:
            // Device rotated right: swap axes, flip both.
            return (x: 1.0 - y, y: 1.0 - x)
        case .portraitUpsideDown:
            // Upside-down portrait: flip X, keep Y from bottom-left.
            return (x: 1.0 - x, y: y)
        }
    }

    // MARK: - Private: Quality Score

    /// Counts the number of visible body joints above the minimum confidence threshold.
    ///
    /// This provides a measure of how much of the body is visible in the frame,
    /// which correlates with detection reliability.
    ///
    /// - Parameter observation: The body pose observation.
    /// - Returns: The count of visible joints.
    private func countVisibleJoints(in observation: VNHumanBodyPoseObservation) -> Int {
        let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
            .rightWrist, .leftWrist,
            .rightElbow, .leftElbow,
            .rightShoulder, .leftShoulder,
            .rightHip, .leftHip,
            .neck, .nose
        ]

        var count = 0
        for joint in keyJoints {
            if let point = try? observation.recognizedPoint(joint),
               point.confidence >= minimumConfidence {
                count += 1
            }
        }
        return count
    }

    /// Calculates a quality score (0-1) for the current detection.
    ///
    /// The score is a weighted combination of:
    /// - Raw detection confidence (40%)
    /// - Body visibility: fraction of key joints visible (30%)
    /// - Prediction consistency: how close the measurement is to the Kalman prediction (30%)
    ///
    /// - Parameters:
    ///   - rawConfidence: The confidence from joint detection (0-1).
    ///   - visibleJointCount: Number of key joints visible above threshold.
    ///   - measuredX: The measured X position after coordinate transformation.
    ///   - measuredY: The measured Y position after coordinate transformation.
    /// - Returns: A quality score from 0 to 1.
    private func calculateQualityScore(
        rawConfidence: Float,
        visibleJointCount: Int,
        measuredX: Double,
        measuredY: Double
    ) -> Float {
        // Component 1: Raw confidence (0-1).
        let confidenceScore = rawConfidence

        // Component 2: Body visibility (0-1). 10 key joints checked.
        let visibilityScore = Float(visibleJointCount) / 10.0

        // Component 3: Consistency with prediction (0-1).
        let consistencyScore: Float
        if kalmanFilter.isInitialized {
            let predicted = kalmanFilter.predictedPosition
            let dx = measuredX - predicted.x
            let dy = measuredY - predicted.y
            let deviation = sqrt(dx * dx + dy * dy)
            consistencyScore = Float(max(0, 1.0 - deviation / maxPredictionDeviation))
        } else {
            // First frame has no prediction; full consistency score.
            consistencyScore = 1.0
        }

        // Weighted combination.
        let quality = 0.4 * confidenceScore + 0.3 * visibilityScore + 0.3 * consistencyScore
        return min(max(quality, 0), 1)
    }
}
