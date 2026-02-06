import AVFoundation
import SwiftUI

/// Wraps AVCaptureSession to allow safe cross-isolation usage.
private final class SessionRunner: @unchecked Sendable {
    let session = AVCaptureSession()

    func start() {
        session.startRunning()
    }

    func stop() {
        session.stopRunning()
    }
}

/// ViewModel for the camera recording screen, managing recording state,
/// duration tracking, and lift type selection.
@Observable
@MainActor
final class RecordViewModel {

    // MARK: - Constants

    /// Maximum allowed recording duration in seconds.
    static let maxRecordingDuration: TimeInterval = 60

    // MARK: - Properties

    var isRecording = false
    var recordingDuration: TimeInterval = 0
    var selectedLiftType: LiftType = .squat
    var recordedVideoURL: URL?
    var error: String?

    private let sessionRunner = SessionRunner()

    /// The underlying capture session for use by the camera preview layer.
    var captureSession: AVCaptureSession { sessionRunner.session }

    private var timer: Timer?

    // MARK: - Initialization

    init(preferredLiftType: LiftType = .squat) {
        self.selectedLiftType = preferredLiftType
    }

    // MARK: - Camera Setup

    /// Configures and starts the camera capture session for preview.
    func setupCamera() {
        let session = sessionRunner.session
        session.beginConfiguration()

        guard let videoDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput)
        else {
            error = NSLocalizedString(
                "error_camera_unavailable",
                comment: "Camera is not available"
            )
            session.commitConfiguration()
            return
        }

        session.addInput(videoInput)
        session.commitConfiguration()

        let runner = sessionRunner
        Task.detached {
            runner.start()
        }
    }

    // MARK: - Recording Actions

    /// Starts recording video and begins the duration timer.
    func startRecording() {
        guard !isRecording else { return }

        isRecording = true
        recordingDuration = 0
        error = nil

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.recordingDuration += 0.1

                if self.recordingDuration >= Self.maxRecordingDuration {
                    self.stopRecording()
                }
            }
        }
    }

    /// Stops recording and invalidates the duration timer.
    func stopRecording() {
        guard isRecording else { return }

        isRecording = false
        timer?.invalidate()
        timer = nil

        // In a production app, the actual file URL would come from the camera output delegate.
        // For now, store a placeholder in the temporary directory.
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        recordedVideoURL = tempURL
    }

    /// Resets all recording state to initial values.
    func resetRecording() {
        isRecording = false
        recordingDuration = 0
        recordedVideoURL = nil
        error = nil
        timer?.invalidate()
        timer = nil
    }

    /// Stops the capture session and cleans up resources.
    func tearDown() {
        timer?.invalidate()
        timer = nil
        let runner = sessionRunner
        Task.detached {
            runner.stop()
        }
    }

    // MARK: - Formatting

    /// The recording duration formatted as M:SS.
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
