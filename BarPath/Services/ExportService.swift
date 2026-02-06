import AVFoundation
import CoreGraphics
import Foundation
import Photos
import UIKit

/// Errors that can occur during video export.
enum ExportError: LocalizedError {
    case noVideoURL
    case noVideoTrack
    case cannotCreateReader
    case cannotCreateWriter
    case cannotAddReaderOutput
    case cannotAddWriterInput
    case exportFailed(String)
    case photosSaveNotAuthorized

    var errorDescription: String? {
        switch self {
        case .noVideoURL:
            return NSLocalizedString(
                "error_export_no_video_url",
                comment: "No video URL available for export"
            )
        case .noVideoTrack:
            return NSLocalizedString(
                "error_export_no_video_track",
                comment: "No video track in source"
            )
        case .cannotCreateReader:
            return NSLocalizedString(
                "error_export_cannot_create_reader",
                comment: "Cannot create asset reader"
            )
        case .cannotCreateWriter:
            return NSLocalizedString(
                "error_export_cannot_create_writer",
                comment: "Cannot create asset writer"
            )
        case .cannotAddReaderOutput:
            return NSLocalizedString(
                "error_export_cannot_add_reader_output",
                comment: "Cannot add reader output"
            )
        case .cannotAddWriterInput:
            return NSLocalizedString(
                "error_export_cannot_add_writer_input",
                comment: "Cannot add writer input"
            )
        case .exportFailed(let reason):
            return String(
                format: NSLocalizedString(
                    "error_export_failed_%@",
                    comment: "Export failed with reason"
                ),
                reason
            )
        case .photosSaveNotAuthorized:
            return NSLocalizedString(
                "error_export_photos_not_authorized",
                comment: "Not authorized to save to Photos"
            )
        }
    }
}

/// Exports a bar path analysis as a video with the bar path drawn as an overlay.
///
/// The overlay draws connected line segments colored by velocity:
/// - Green for slow movement
/// - Yellow for medium movement
/// - Red for fast movement
///
/// Uses `AVAssetReader` to read the original video frames and `AVAssetWriter`
/// to compose the output with the overlay drawn via Core Graphics.
struct ExportService {

    // MARK: - Constants

    /// Line width for the bar path overlay, in points.
    private static let pathLineWidth: CGFloat = 4.0

    /// Radius of the dot drawn at the current bar position, in points.
    private static let dotRadius: CGFloat = 8.0

    // MARK: - Public API

    /// Exports the analysis as a video with the bar path overlay drawn on each frame.
    ///
    /// - Parameters:
    ///   - analysis: The bar path analysis containing points and source video URL.
    ///   - onProgress: Optional callback reporting export progress (0.0 to 1.0).
    /// - Returns: The file URL of the exported video in a temporary directory.
    /// - Throws: `ExportError` if the source video cannot be read or the export fails.
    static func exportVideo(
        from analysis: BarPathAnalysis,
        onProgress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> URL {
        guard let sourceURL = analysis.videoURL else {
            throw ExportError.noVideoURL
        }

        let asset = AVURLAsset(url: sourceURL)

        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw ExportError.noVideoTrack
        }

        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let duration = try await asset.load(.duration)

        // Determine the actual rendered size after applying the transform.
        let transformedSize = naturalSize.applying(preferredTransform)
        let videoWidth = abs(transformedSize.width)
        let videoHeight = abs(transformedSize.height)

        // Set up reader.
        let reader: AVAssetReader
        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            throw ExportError.cannotCreateReader
        }

        let readerOutputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let readerOutput = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: readerOutputSettings
        )
        readerOutput.alwaysCopiesSampleData = false

        guard reader.canAdd(readerOutput) else {
            throw ExportError.cannotAddReaderOutput
        }
        reader.add(readerOutput)

        // Set up writer.
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BarPath_Export_\(UUID().uuidString).mp4")

        // Remove any existing file at the output path.
        try? FileManager.default.removeItem(at: outputURL)

        let writer: AVAssetWriter
        do {
            writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        } catch {
            throw ExportError.cannotCreateWriter
        }

        let writerInputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoWidth,
            AVVideoHeightKey: videoHeight
        ]
        let writerInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: writerInputSettings
        )
        writerInput.expectsMediaDataInRealTime = false
        writerInput.transform = preferredTransform

        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(videoWidth),
            kCVPixelBufferHeightKey as String: Int(videoHeight)
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: pixelBufferAttributes
        )

        guard writer.canAdd(writerInput) else {
            throw ExportError.cannotAddWriterInput
        }
        writer.add(writerInput)

        guard reader.startReading() else {
            throw ExportError.cannotCreateReader
        }
        guard writer.startWriting() else {
            throw ExportError.cannotCreateWriter
        }
        writer.startSession(atSourceTime: .zero)

        // Precompute velocities for coloring.
        let velocities = BarPathAnalyzer.calculateVelocities(analysis.points)
        let maxVelocity = velocities.max() ?? 1.0

        let totalDurationSeconds = CMTimeGetSeconds(duration)
        var frameIndex = 0

        // Process frames.
        while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let timestamp = CMTimeGetSeconds(presentationTime)

            guard let sourcePixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                continue
            }

            // Draw the overlay onto a new pixel buffer.
            guard let outputPixelBuffer = drawOverlay(
                on: sourcePixelBuffer,
                timestamp: timestamp,
                points: analysis.points,
                velocities: velocities,
                maxVelocity: maxVelocity,
                videoSize: CGSize(width: videoWidth, height: videoHeight)
            ) else {
                continue
            }

            // Wait for the writer input to be ready.
            while !writerInput.isReadyForMoreMediaData {
                try await Task.sleep(for: .milliseconds(10))
            }

            adaptor.append(outputPixelBuffer, withPresentationTime: presentationTime)

            frameIndex += 1
            if totalDurationSeconds > 0 {
                onProgress?(min(timestamp / totalDurationSeconds, 1.0))
            }
        }

        // Finish writing.
        writerInput.markAsFinished()
        await writer.finishWriting()
        reader.cancelReading()

        if writer.status == .failed {
            throw ExportError.exportFailed(writer.error?.localizedDescription ?? "Unknown error")
        }

        onProgress?(1.0)

        return outputURL
    }

    /// Saves an exported video to the user's Photos library.
    ///
    /// - Parameter url: The file URL of the video to save.
    /// - Throws: `ExportError.photosSaveNotAuthorized` if the user has not granted Photos access.
    static func saveToPhotosLibrary(url: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)

        guard status == .authorized || status == .limited else {
            throw ExportError.photosSaveNotAuthorized
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(
                with: .video,
                fileURL: url,
                options: nil
            )
        }
    }

    // MARK: - Overlay Drawing

    /// Draws the bar path overlay onto a copy of the source pixel buffer.
    ///
    /// - Parameters:
    ///   - sourceBuffer: The original video frame.
    ///   - timestamp: The current frame's presentation time.
    ///   - points: All bar path points from the analysis.
    ///   - velocities: Precomputed velocities for each point.
    ///   - maxVelocity: The maximum velocity value for normalization.
    ///   - videoSize: The dimensions of the video frame.
    /// - Returns: A new pixel buffer with the overlay drawn, or `nil` on failure.
    private static func drawOverlay(
        on sourceBuffer: CVPixelBuffer,
        timestamp: TimeInterval,
        points: [BarPathPoint],
        velocities: [Double],
        maxVelocity: Double,
        videoSize: CGSize
    ) -> CVPixelBuffer? {
        let width = CVPixelBufferGetWidth(sourceBuffer)
        let height = CVPixelBufferGetHeight(sourceBuffer)

        // Find points up to the current timestamp.
        let visiblePoints = points.filter { $0.timestamp <= timestamp }
        guard !visiblePoints.isEmpty else { return sourceBuffer }

        CVPixelBufferLockBaseAddress(sourceBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(sourceBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(sourceBuffer) else {
            return nil
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(sourceBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return nil
        }

        // Core Graphics has origin at bottom-left; our points use top-left origin.
        // Convert: CG_y = height - (normalizedY * height)
        let frameWidth = CGFloat(width)
        let frameHeight = CGFloat(height)

        context.setLineWidth(pathLineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        // Draw path segments with velocity-based coloring.
        for i in 1..<visiblePoints.count {
            let prev = visiblePoints[i - 1]
            let curr = visiblePoints[i]

            let prevX = CGFloat(prev.x) * frameWidth
            let prevY = frameHeight - CGFloat(prev.y) * frameHeight
            let currX = CGFloat(curr.x) * frameWidth
            let currY = frameHeight - CGFloat(curr.y) * frameHeight

            // Find the velocity index in the full points array.
            let pointIndex = points.firstIndex(where: { $0.id == curr.id }) ?? i
            let velocity = pointIndex < velocities.count ? velocities[pointIndex] : 0
            let color = velocityColor(velocity: velocity, maxVelocity: maxVelocity)

            context.setStrokeColor(color)
            context.beginPath()
            context.move(to: CGPoint(x: prevX, y: prevY))
            context.addLine(to: CGPoint(x: currX, y: currY))
            context.strokePath()
        }

        // Draw a dot at the current position (last visible point).
        if let currentPoint = visiblePoints.last {
            let dotX = CGFloat(currentPoint.x) * frameWidth
            let dotY = frameHeight - CGFloat(currentPoint.y) * frameHeight

            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.9))
            context.fillEllipse(in: CGRect(
                x: dotX - dotRadius,
                y: dotY - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
        }

        return sourceBuffer
    }

    /// Returns a CGColor corresponding to the velocity, interpolating from green (slow)
    /// through yellow (medium) to red (fast).
    ///
    /// - Parameters:
    ///   - velocity: The velocity value for this segment.
    ///   - maxVelocity: The maximum velocity for normalization.
    /// - Returns: A CGColor in the green-yellow-red gradient.
    private static func velocityColor(velocity: Double, maxVelocity: Double) -> CGColor {
        let normalizedVelocity = maxVelocity > 0 ? min(velocity / maxVelocity, 1.0) : 0

        let red: CGFloat
        let green: CGFloat

        if normalizedVelocity < 0.5 {
            // Green to yellow: increase red, keep green at 1.
            red = CGFloat(normalizedVelocity * 2.0)
            green = 1.0
        } else {
            // Yellow to red: keep red at 1, decrease green.
            red = 1.0
            green = CGFloat(1.0 - (normalizedVelocity - 0.5) * 2.0)
        }

        return CGColor(red: red, green: green, blue: 0, alpha: 0.85)
    }
}
