import AVFoundation
import CoreGraphics
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

/// Delegate for AVCaptureVideoDataOutput that forwards sample buffers for live pose detection.
private final class SampleBufferDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    var onSampleBuffer: (@Sendable (CMSampleBuffer) -> Void)?

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        onSampleBuffer?(sampleBuffer)
    }
}

/// Wraps AVCaptureSession to allow safe cross-isolation usage.
private final class SessionRunner: @unchecked Sendable {
    let session = AVCaptureSession()
    let movieFileOutput = AVCaptureMovieFileOutput()
    let videoDataOutput = AVCaptureVideoDataOutput()
    let outputDelegate = MovieFileOutputDelegate()
    let sampleBufferDelegate = SampleBufferDelegate()

    /// Dedicated serial queue for video data output to avoid frame drops.
    let videoDataQueue = DispatchQueue(label: "app.barpath.videodata", qos: .userInitiated)

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
/// duration tracking, lift type selection, and live bar path overlay.
@Observable
@MainActor
final class RecordViewModel {

    // MARK: - Constants

    /// Maximum allowed recording duration in seconds.
    static let maxRecordingDuration: TimeInterval = 60

    /// Minimum interval between processed frames for live tracking (seconds).
    /// Limits pose detection to ~15 fps to balance accuracy and performance.
    private static let liveTrackingInterval: TimeInterval = 1.0 / 15.0

    // MARK: - Properties

    var isRecording = false
    var recordingDuration: TimeInterval = 0
    var selectedLiftType: LiftType = .squat
    var recordedVideoURL: URL?
    var error: String?
    var cameraPermissionDenied = false

    // MARK: - Live Tracking Properties

    /// Accumulated bar path points detected during the current recording session.
    /// Views can observe this array to render the live bar path overlay.
    var livePoints: [BarPathPoint] = []

    /// The most recently detected wrist position in normalized coordinates (0-1).
    /// Views can use this to render a live tracking dot at the current bar position.
    var currentTrackingPoint: CGPoint?

    /// Whether audio/haptic feedback is enabled for velocity changes during recording.
    var audioFeedbackEnabled = false

    // MARK: - Private Properties

    private let sessionRunner = SessionRunner()
    private let recordingFPS: RecordingFPS
    private let poseDetectionService: PoseDetecting
    private var hapticsEnabled: Bool

    /// The underlying capture session for use by the camera preview layer.
    var captureSession: AVCaptureSession { sessionRunner.session }

    private var timer: Timer?

    /// Timestamp of the last processed frame, used to throttle pose detection.
    private var lastProcessedFrameTime: TimeInterval = 0

    /// Reference time for computing frame timestamps relative to recording start.
    private var recordingStartTime: Date?

    // MARK: - Initialization

    init(
        preferredLiftType: LiftType = .squat,
        recordingFPS: RecordingFPS = .sixty,
        poseDetectionService: PoseDetecting = PoseDetectionService(),
        hapticsEnabled: Bool = true
    ) {
        self.selectedLiftType = preferredLiftType
        self.recordingFPS = recordingFPS
        self.poseDetectionService = poseDetectionService
        self.hapticsEnabled = hapticsEnabled
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

    /// Configures and starts the camera capture session for preview and live tracking.
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

        // Add video data output for live pose detection
        let videoDataOutput = sessionRunner.videoDataOutput
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            videoDataOutput.setSampleBufferDelegate(
                sessionRunner.sampleBufferDelegate,
                queue: sessionRunner.videoDataQueue
            )
        }

        // Wire up the sample buffer callback for live tracking
        configureSampleBufferHandler()

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
        livePoints = []
        currentTrackingPoint = nil
        lastProcessedFrameTime = 0
        recordingStartTime = Date()

        if hapticsEnabled {
            HapticManager.shared.recordingStarted()
        }

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

        if hapticsEnabled {
            HapticManager.shared.recordingStopped()
        }
    }

    /// Resets all recording state to initial values.
    func resetRecording() {
        isRecording = false
        recordingDuration = 0
        recordedVideoURL = nil
        error = nil
        timer?.invalidate()
        timer = nil
        livePoints = []
        currentTrackingPoint = nil
        lastProcessedFrameTime = 0
        recordingStartTime = nil
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

    // MARK: - Live Tracking

    /// Wires the sample buffer delegate callback to process frames for live pose detection.
    /// The callback runs on a background queue; state updates are dispatched to the main actor.
    private func configureSampleBufferHandler() {
        let poseService = poseDetectionService
        let runner = sessionRunner

        runner.sampleBufferDelegate.onSampleBuffer = { [weak self] sampleBuffer in
            guard let self else { return }

            // Extract data from sample buffer on the callback queue
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let frameTime = CMTimeGetSeconds(presentationTime)
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }

            // CVPixelBuffer is reference-counted and safe to share read-only.
            // Suppress Sendable warning since we're only reading from the buffer.
            nonisolated(unsafe) let unsafePixelBuffer = pixelBuffer

            // Check throttling on main actor
            Task { @MainActor [weak self] in
                guard let self, self.isRecording else { return }

                let elapsed = frameTime - self.lastProcessedFrameTime
                guard elapsed >= Self.liveTrackingInterval || self.lastProcessedFrameTime == 0 else {
                    return
                }

                self.lastProcessedFrameTime = frameTime

                // Compute timestamp relative to recording start
                let timestamp: TimeInterval
                if let startTime = self.recordingStartTime {
                    timestamp = Date().timeIntervalSince(startTime)
                } else {
                    timestamp = 0
                }

                // Run pose detection on a background task
                Task.detached { [weak self] in
                    let point = try? await poseService.detectPose(in: unsafePixelBuffer, timestamp: timestamp)

                    // Update state on main actor
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        if let point {
                            self.livePoints.append(point)
                            self.currentTrackingPoint = point.cgPoint
                        } else {
                            self.currentTrackingPoint = nil
                        }
                    }
                }
            }
        }
    }
}
