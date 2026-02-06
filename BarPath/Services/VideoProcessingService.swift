import AVFoundation
import Foundation

/// Errors that can occur during video processing.
enum VideoProcessingError: LocalizedError {
    case cannotOpenVideo
    case cannotCreateReader
    case cannotAddOutput
    case noVideoTrack
    case processingCancelled

    var errorDescription: String? {
        switch self {
        case .cannotOpenVideo:
            return NSLocalizedString(
                "error_cannot_open_video",
                comment: "Cannot open video file"
            )
        case .cannotCreateReader:
            return NSLocalizedString(
                "error_cannot_create_reader",
                comment: "Cannot create asset reader"
            )
        case .cannotAddOutput:
            return NSLocalizedString(
                "error_cannot_add_output",
                comment: "Cannot add reader output"
            )
        case .noVideoTrack:
            return NSLocalizedString(
                "error_no_video_track",
                comment: "No video track found"
            )
        case .processingCancelled:
            return NSLocalizedString(
                "error_processing_cancelled",
                comment: "Video processing was cancelled"
            )
        }
    }
}

/// Processes a recorded video file by extracting frames and running pose detection
/// on each one, producing an array of bar path points.
///
/// Progress is reported via a callback so the UI can display a progress indicator.
/// Processing supports cancellation through Swift concurrency's cooperative model.
final class VideoProcessingService: Sendable {

    // MARK: - Properties

    private let poseDetector: PoseDetecting

    /// The number of frames to process before yielding to the cooperative task scheduler.
    private let batchSize = 10

    // MARK: - Initialization

    /// Creates a new video processing service.
    ///
    /// - Parameter poseDetector: The pose detection implementation to use for each frame.
    init(poseDetector: PoseDetecting = PoseDetectionService()) {
        self.poseDetector = poseDetector
    }

    // MARK: - Public API

    /// Processes all frames in a video and returns detected bar path points.
    ///
    /// Frames are extracted using `AVAssetReader` and fed through the pose detector.
    /// Progress is reported after each batch of frames. Processing respects task
    /// cancellation via `Task.isCancelled`.
    ///
    /// - Parameters:
    ///   - videoURL: The file URL of the video to process.
    ///   - onProgress: A callback invoked on the main actor with a value between 0.0 and 1.0.
    /// - Returns: An array of `BarPathPoint` values detected across all frames.
    /// - Throws: `VideoProcessingError` if the video cannot be read or processing is cancelled.
    func processVideo(
        at videoURL: URL,
        onProgress: @MainActor @Sendable (Double) -> Void
    ) async throws -> [BarPathPoint] {
        let asset = AVURLAsset(url: videoURL)

        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoProcessingError.noVideoTrack
        }

        let duration = try await asset.load(.duration)
        let totalDurationSeconds = CMTimeGetSeconds(duration)
        guard totalDurationSeconds > 0 else {
            return []
        }

        let reader: AVAssetReader
        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            throw VideoProcessingError.cannotCreateReader
        }

        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let trackOutput = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: outputSettings
        )
        trackOutput.alwaysCopiesSampleData = false

        guard reader.canAdd(trackOutput) else {
            throw VideoProcessingError.cannotAddOutput
        }
        reader.add(trackOutput)

        guard reader.startReading() else {
            throw VideoProcessingError.cannotOpenVideo
        }

        var points: [BarPathPoint] = []
        var frameCount = 0
        let estimatedTotalFrames = try await estimateFrameCount(
            track: videoTrack,
            duration: duration
        )

        while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
            if Task.isCancelled {
                reader.cancelReading()
                throw VideoProcessingError.processingCancelled
            }

            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let timestamp = CMTimeGetSeconds(presentationTime)

            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                do {
                    if let point = try await poseDetector.detectPose(
                        in: pixelBuffer,
                        timestamp: timestamp
                    ) {
                        points.append(point)
                    }
                } catch {
                    // Skip frames where pose detection fails rather than
                    // aborting the entire video processing pipeline.
                }
            }

            frameCount += 1

            // Report progress and yield after each batch.
            if frameCount % batchSize == 0 {
                let progress = min(Double(frameCount) / Double(estimatedTotalFrames), 1.0)
                await onProgress(progress)
                await Task.yield()
            }
        }

        // Report completion.
        await onProgress(1.0)

        reader.cancelReading()

        return points
    }

    // MARK: - Private

    /// Estimates the total number of frames in the video track.
    ///
    /// Uses the track's nominal frame rate and the asset's duration. Falls back to
    /// 30 fps if the frame rate is unavailable.
    ///
    /// - Parameters:
    ///   - track: The video track.
    ///   - duration: The total asset duration.
    /// - Returns: The estimated number of frames.
    private func estimateFrameCount(
        track: AVAssetTrack,
        duration: CMTime
    ) async throws -> Int {
        let frameRate = try await track.load(.nominalFrameRate)
        let effectiveFrameRate = frameRate > 0 ? frameRate : 30.0
        let totalSeconds = CMTimeGetSeconds(duration)
        return max(1, Int(totalSeconds * Double(effectiveFrameRate)))
    }
}
