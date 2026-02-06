import AVFoundation

/// Protocol abstracting video frame extraction from a recorded or imported video file.
/// Enables dependency injection and testability by decoupling frame extraction
/// from the analysis pipeline.
protocol VideoProcessing: Sendable {

    /// Extracts frames from a video at the given URL.
    ///
    /// - Parameters:
    ///   - url: The file URL of the video to process.
    ///   - fps: The frame rate at which to sample the video.
    ///   - progress: A callback reporting extraction progress (0-1).
    /// - Returns: An array of tuples containing the pixel buffer and its timestamp.
    func extractFrames(
        from url: URL,
        fps: Double,
        progress: @Sendable (Double) -> Void
    ) async throws -> [(CVPixelBuffer, TimeInterval)]
}
