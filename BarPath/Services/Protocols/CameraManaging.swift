import AVFoundation

/// Protocol abstracting camera session management and video recording.
/// Enables dependency injection and testability by decoupling camera hardware
/// access from the recording UI.
@MainActor
protocol CameraManaging: AnyObject, Sendable {

    /// The underlying capture session for preview display.
    var captureSession: AVCaptureSession { get }

    /// Configures and starts the camera capture session.
    ///
    /// - Parameter fps: The desired recording frame rate.
    func startSession(fps: Int) async throws

    /// Stops the camera capture session and releases resources.
    func stopSession()

    /// Begins recording video to a temporary file.
    ///
    /// - Returns: The file URL where the video will be written.
    func startRecording() throws -> URL

    /// Stops the active recording.
    ///
    /// - Returns: The file URL of the completed recording.
    func stopRecording() async throws -> URL
}
