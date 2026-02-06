import Testing
import Foundation
@testable import BarPath

@Suite("AnalysisViewModel Tests")
@MainActor
struct AnalysisViewModelTests {

    // MARK: - Initial State

    @Test("Initial state is not processing")
    func initialStateNotProcessing() {
        let persistence = MockPersistenceService()
        let viewModel = AnalysisViewModel(
            videoProcessor: VideoProcessingService(poseDetector: MockPoseDetectionService()),
            persistence: persistence
        )

        #expect(viewModel.isProcessing == false)
    }

    @Test("Initial state has no error")
    func initialStateNoError() {
        let persistence = MockPersistenceService()
        let viewModel = AnalysisViewModel(
            videoProcessor: VideoProcessingService(poseDetector: MockPoseDetectionService()),
            persistence: persistence
        )

        #expect(viewModel.error == nil)
    }

    @Test("Initial progress is zero")
    func initialProgressIsZero() {
        let persistence = MockPersistenceService()
        let viewModel = AnalysisViewModel(
            videoProcessor: VideoProcessingService(poseDetector: MockPoseDetectionService()),
            persistence: persistence
        )

        #expect(viewModel.progress == 0.0)
    }

    @Test("Initial state has no analysis result")
    func initialStateNoAnalysis() {
        let persistence = MockPersistenceService()
        let viewModel = AnalysisViewModel(
            videoProcessor: VideoProcessingService(poseDetector: MockPoseDetectionService()),
            persistence: persistence
        )

        #expect(viewModel.analysis == nil)
    }

    @Test("Initial status message is empty")
    func initialStatusMessageEmpty() {
        let persistence = MockPersistenceService()
        let viewModel = AnalysisViewModel(
            videoProcessor: VideoProcessingService(poseDetector: MockPoseDetectionService()),
            persistence: persistence
        )

        #expect(viewModel.statusMessage == "")
    }

    // MARK: - Cancel Processing

    @Test("cancelProcessing resets state")
    func cancelProcessingResetsState() {
        let persistence = MockPersistenceService()
        let viewModel = AnalysisViewModel(
            videoProcessor: VideoProcessingService(poseDetector: MockPoseDetectionService()),
            persistence: persistence
        )

        viewModel.cancelProcessing()

        #expect(viewModel.isProcessing == false)
        #expect(viewModel.progress == 0)
        #expect(viewModel.statusMessage == "")
    }

    // MARK: - Guard Against Double Processing

    @Test("processVideo does not start if already processing")
    func processVideoGuardsAgainstDoubleProcessing() {
        let persistence = MockPersistenceService()
        let mockDetector = MockPoseDetectionService()
        let viewModel = AnalysisViewModel(
            videoProcessor: VideoProcessingService(poseDetector: mockDetector),
            persistence: persistence
        )

        // Manually set isProcessing to simulate an in-flight operation
        viewModel.isProcessing = true

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.mp4")
        viewModel.processVideo(url: tempURL, liftType: .squat)

        // The mock detector should not have been invoked since processing was guarded
        #expect(mockDetector.detectCallCount == 0)
    }

    // MARK: - State Transitions

    @Test("processVideo sets isProcessing and clears previous error")
    func processVideoSetsProcessingState() {
        let persistence = MockPersistenceService()
        let mockDetector = MockPoseDetectionService()
        let viewModel = AnalysisViewModel(
            videoProcessor: VideoProcessingService(poseDetector: mockDetector),
            persistence: persistence
        )

        viewModel.error = "Previous error"
        viewModel.analysis = TestData.makeAnalysis()

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("nonexistent.mp4")
        viewModel.processVideo(url: tempURL, liftType: .squat)

        // isProcessing should be true immediately after calling processVideo
        #expect(viewModel.isProcessing == true)
        // Previous error should be cleared
        #expect(viewModel.error == nil)
        // Previous analysis should be cleared
        #expect(viewModel.analysis == nil)
        // Progress should be reset
        #expect(viewModel.progress == 0)

        // Cancel to clean up the Task
        viewModel.cancelProcessing()
    }

    // MARK: - Dependency Injection

    @Test("AnalysisViewModel accepts injected dependencies")
    func dependencyInjection() {
        let mockDetector = MockPoseDetectionService()
        let mockPersistence = MockPersistenceService()
        let processor = VideoProcessingService(poseDetector: mockDetector)

        let viewModel = AnalysisViewModel(
            videoProcessor: processor,
            persistence: mockPersistence
        )

        // ViewModel should be created without error
        #expect(viewModel.isProcessing == false)
        #expect(viewModel.analysis == nil)
    }
}
