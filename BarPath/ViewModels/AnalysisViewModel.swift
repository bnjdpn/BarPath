import SwiftUI

/// ViewModel for the video processing screen, coordinating the frame extraction,
/// pose detection, and analysis pipeline while reporting progress to the UI.
@Observable
@MainActor
final class AnalysisViewModel {

    // MARK: - Properties

    var progress: Double = 0
    var isProcessing = false
    var error: String?
    var analysis: BarPathAnalysis?
    var statusMessage: String = ""

    private let videoProcessor: VideoProcessingService
    private let persistence: DataStoring
    private var processingTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        videoProcessor: VideoProcessingService = VideoProcessingService(),
        persistence: DataStoring = PersistenceService()
    ) {
        self.videoProcessor = videoProcessor
        self.persistence = persistence
    }

    // MARK: - Processing

    /// Processes a recorded video through the full analysis pipeline:
    /// frame extraction + pose detection -> rep detection -> metrics calculation.
    ///
    /// - Parameters:
    ///   - url: The file URL of the video to analyze.
    ///   - liftType: The type of lift being performed.
    ///   - calibration: Optional calibration data for real-world unit conversion.
    func processVideo(url: URL, liftType: LiftType, calibration: CalibrationData? = nil) {
        guard !isProcessing else { return }

        isProcessing = true
        progress = 0
        error = nil
        analysis = nil

        processingTask = Task {
            do {
                // Phase 1: Extract frames and detect poses (0% - 80%)
                statusMessage = NSLocalizedString(
                    "status_analyzing_frames",
                    comment: "Analyzing frames status"
                )

                let points = try await videoProcessor.processVideo(
                    at: url
                ) { [weak self] frameProgress in
                    guard let self else { return }
                    self.progress = frameProgress * 0.8

                    if frameProgress < 0.5 {
                        self.statusMessage = NSLocalizedString(
                            "status_analyzing_frames",
                            comment: "Analyzing frames status"
                        )
                    } else {
                        self.statusMessage = NSLocalizedString(
                            "status_detecting_reps",
                            comment: "Detecting reps status"
                        )
                    }
                }

                guard !Task.isCancelled else { return }

                // Phase 2: Analyze path and compute metrics (80% - 100%)
                statusMessage = NSLocalizedString(
                    "status_calculating_metrics",
                    comment: "Calculating metrics status"
                )
                progress = 0.85

                let result = BarPathAnalyzer.analyze(
                    points: points,
                    liftType: liftType,
                    calibration: calibration,
                    videoURL: url
                )

                progress = 0.95

                // Save to persistence
                try persistence.saveAnalysis(result)
                progress = 1.0

                analysis = result
                isProcessing = false

            } catch {
                guard !Task.isCancelled else { return }
                self.error = error.localizedDescription
                isProcessing = false
            }
        }
    }

    /// Cancels the current processing operation.
    func cancelProcessing() {
        processingTask?.cancel()
        processingTask = nil
        isProcessing = false
        progress = 0
        statusMessage = ""
    }
}
