import AVFoundation
import SwiftUI

/// Delegate for AVCaptureMovieFileOutput recording callbacks.
private final class MovieFileOutputDelegate: NSObject, AVCaptureFileOutputRecordingDelegate, @unchecked Sendable {
    var onFinished: (@Sendable (Result<URL, Error>) -> Void)?

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: (any Error)?
    ) {
        if let error {
            onFinished?(.failure(error))
        } else {
            onFinished?(.success(outputFileURL))
        }
        onFinished = nil
    }
}

/// Wraps AVCaptureSession to allow safe cross-isolation usage.
private final class SessionRunner: @unchecked Sendable {
    let session = AVCaptureSession()
    let movieFileOutput = AVCaptureMovieFileOutput()
    let outputDelegate = MovieFileOutputDelegate()

    func start() {
        session.startRunning()
    }

    func stop() {
        session.stopRunning()
    }

    func startRecording(to url: URL) {
        movieFileOutput.startRecording(to: url, recordingDelegate: outputDelegate)
    }

    func stopRecording() {
        movieFileOutput.stopRecording()
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
    var cameraPermissionDenied = false

    private let sessionRunner = SessionRunner()
    private let recordingFPS: RecordingFPS

    /// The underlying capture session for use by the camera preview layer.
    var captureSession: AVCaptureSession { sessionRunner.session }

    private var timer: Timer?

    // MARK: - Initialization

    init(preferredLiftType: LiftType = .squat, recordingFPS: RecordingFPS = .sixty) {
        self.selectedLiftType = preferredLiftType
        self.recordingFPS = recordingFPS
    }

    // MARK: - Camera Permission

    /// Checks camera authorization status and requests permission if needed.
    func checkCameraPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionDenied = false
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraPermissionDenied = !granted
        case .denied, .restricted:
            cameraPermissionDenied = true
        @unknown default:
            cameraPermissionDenied = true
        }
    }

    /// Opens the system Settings app so the user can grant camera permission.
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
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

        // Configure frame rate
        let desiredFPS = recordingFPS.rawValue
        do {
            try videoDevice.lockForConfiguration()
            let targetDuration = CMTime(value: 1, timescale: CMTimeScale(desiredFPS))
            videoDevice.activeVideoMinFrameDuration = targetDuration
            videoDevice.activeVideoMaxFrameDuration = targetDuration
            videoDevice.unlockForConfiguration()
        } catch {
            // Frame rate configuration failed; continue with default rate.
        }

        // Add movie file output
        if session.canAddOutput(sessionRunner.movieFileOutput) {
            session.addOutput(sessionRunner.movieFileOutput)
        }

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

        // Generate a timestamped filename
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let filename = "BarPath_\(timestamp).mov"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        // Remove any existing file at this path
        try? FileManager.default.removeItem(at: outputURL)

        // Set up the delegate callback
        let runner = sessionRunner
        runner.outputDelegate.onFinished = { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let url):
                    self.recordedVideoURL = url
                case .failure:
                    self.error = NSLocalizedString(
                        "error_recording_failed",
                        comment: "Recording failed"
                    )
                }
            }
        }

        runner.startRecording(to: outputURL)

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

        sessionRunner.stopRecording()
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
