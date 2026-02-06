import Testing
import Foundation
@testable import BarPath

@Suite("ResultViewModel Tests")
@MainActor
struct ResultViewModelTests {

    // MARK: - Helpers

    private func makeViewModel(
        analysis: BarPathAnalysis? = nil
    ) -> ResultViewModel {
        let analysisData = analysis ?? TestData.makeAnalysis(repCount: 3)
        return ResultViewModel(analysis: analysisData)
    }

    // MARK: - Initial State

    @Test("Initial state has no selected rep")
    func initialStateNoSelectedRep() {
        let viewModel = makeViewModel()

        #expect(viewModel.selectedRep == nil)
    }

    @Test("Analysis is available immediately after init")
    func analysisAvailableAfterInit() {
        let analysis = TestData.makeAnalysis(repCount: 3)
        let viewModel = makeViewModel(analysis: analysis)

        #expect(viewModel.analysis.id == analysis.id)
        #expect(viewModel.analysis.liftType == .squat)
    }

    @Test("showMetrics defaults to true")
    func showMetricsDefaultsToTrue() {
        let viewModel = makeViewModel()

        #expect(viewModel.showMetrics == true)
    }

    // MARK: - Select Rep

    @Test("selectRep updates selectedRep")
    func selectRepUpdatesSelection() {
        let viewModel = makeViewModel()

        viewModel.selectRep(0)
        #expect(viewModel.selectedRep == 0)

        viewModel.selectRep(2)
        #expect(viewModel.selectedRep == 2)
    }

    @Test("selectRep with nil deselects rep")
    func selectRepWithNilDeselects() {
        let viewModel = makeViewModel()

        viewModel.selectRep(1)
        #expect(viewModel.selectedRep == 1)

        viewModel.selectRep(nil)
        #expect(viewModel.selectedRep == nil)
    }

    // MARK: - Selected Rep Segment

    @Test("selectedRepSegment returns correct segment when rep is selected")
    func selectedRepSegmentReturnsCorrect() {
        let analysis = TestData.makeAnalysis(repCount: 3)
        let viewModel = makeViewModel(analysis: analysis)

        viewModel.selectRep(0)

        let segment = viewModel.selectedRepSegment
        #expect(segment != nil)
        #expect(segment?.repNumber == 1)
    }

    @Test("selectedRepSegment is nil when no rep is selected")
    func selectedRepSegmentNilWhenNoSelection() {
        let viewModel = makeViewModel()

        #expect(viewModel.selectedRepSegment == nil)
    }

    @Test("selectedRepSegment is nil when index is out of bounds")
    func selectedRepSegmentNilWhenOutOfBounds() {
        let analysis = TestData.makeAnalysis(repCount: 1)
        let viewModel = makeViewModel(analysis: analysis)

        viewModel.selectRep(99)

        #expect(viewModel.selectedRepSegment == nil)
    }

    @Test("selectedRepSegment is nil for negative index")
    func selectedRepSegmentNilForNegativeIndex() {
        let viewModel = makeViewModel()

        viewModel.selectRep(-1)

        #expect(viewModel.selectedRepSegment == nil)
    }

    // MARK: - Display Points

    @Test("displayPoints returns all points when no rep is selected")
    func displayPointsReturnsAllWhenNoSelection() {
        let analysis = TestData.makeAnalysis(repCount: 2)
        let viewModel = makeViewModel(analysis: analysis)

        #expect(viewModel.displayPoints.count == analysis.points.count)
    }

    @Test("displayPoints returns subset when rep is selected")
    func displayPointsReturnsSubsetWhenRepSelected() {
        let analysis = TestData.makeAnalysis(repCount: 3)
        let viewModel = makeViewModel(analysis: analysis)

        viewModel.selectRep(0)

        let repPoints = viewModel.displayPoints
        // The displayed points should be fewer than all points
        #expect(repPoints.count < analysis.points.count)
        #expect(repPoints.count > 0)
    }

    @Test("displayPoints returns all points for invalid index")
    func displayPointsReturnsAllForInvalidIndex() {
        let analysis = TestData.makeAnalysis(repCount: 2)
        let viewModel = makeViewModel(analysis: analysis)

        viewModel.selectRep(99)

        #expect(viewModel.displayPoints.count == analysis.points.count)
    }

    // MARK: - Formatted Metric Strings

    @Test("Formatted peak velocity string is non-empty")
    func formattedPeakVelocity() {
        let analysis = TestData.makeAnalysis(repCount: 3)
        let viewModel = makeViewModel(analysis: analysis)

        let formatted = viewModel.formattedPeakVelocity
        #expect(!formatted.isEmpty)
    }

    @Test("Formatted peak velocity contains numeric value")
    func formattedPeakVelocityContainsNumber() {
        let analysis = TestData.makeAnalysis(repCount: 2)
        let viewModel = makeViewModel(analysis: analysis)

        let formatted = viewModel.formattedPeakVelocity
        // Should contain at least one digit
        #expect(formatted.contains(where: { $0.isNumber }))
    }

    @Test("Formatted rep count shows correct number")
    func formattedRepCount() {
        let analysis = TestData.makeAnalysis(repCount: 3)
        let viewModel = makeViewModel(analysis: analysis)

        let formatted = viewModel.formattedRepCount
        #expect(formatted.contains("3"))
    }

    @Test("Formatted average velocity is non-empty")
    func formattedAverageVelocity() {
        let analysis = TestData.makeAnalysis(repCount: 2)
        let viewModel = makeViewModel(analysis: analysis)

        let formatted = viewModel.formattedAverageVelocity
        #expect(!formatted.isEmpty)
    }

    @Test("Formatted consistency is non-empty and contains percent")
    func formattedConsistency() {
        let analysis = TestData.makeAnalysis(repCount: 3)
        let viewModel = makeViewModel(analysis: analysis)

        let formatted = viewModel.formattedConsistency
        #expect(!formatted.isEmpty)
        #expect(formatted.contains("%"))
    }

    @Test("Formatted displacement is non-empty")
    func formattedDisplacement() {
        let analysis = TestData.makeAnalysis(repCount: 2)
        let viewModel = makeViewModel(analysis: analysis)

        let formatted = viewModel.formattedDisplacement
        #expect(!formatted.isEmpty)
    }

    @Test("Formatted drift is non-empty")
    func formattedDrift() {
        let analysis = TestData.makeAnalysis(repCount: 2)
        let viewModel = makeViewModel(analysis: analysis)

        let formatted = viewModel.formattedDrift
        #expect(!formatted.isEmpty)
    }

    @Test("Formatted average rep duration contains 's'")
    func formattedAverageRepDuration() {
        let analysis = TestData.makeAnalysis(repCount: 2)
        let viewModel = makeViewModel(analysis: analysis)

        let formatted = viewModel.formattedAverageRepDuration
        #expect(!formatted.isEmpty)
        #expect(formatted.contains("s"))
    }

    @Test("Formatted date is non-empty")
    func formattedDate() {
        let analysis = TestData.makeAnalysis(repCount: 1)
        let viewModel = makeViewModel(analysis: analysis)

        let formatted = viewModel.formattedDate
        #expect(!formatted.isEmpty)
    }

    // MARK: - Zero Reps Edge Case

    @Test("Formatted metrics handle zero reps gracefully")
    func formattedMetricsWithZeroReps() {
        let analysis = BarPathAnalysis(
            liftType: .squat,
            points: [],
            reps: [],
            metrics: AnalysisMetrics.calculate(from: []),
            duration: 0
        )
        let viewModel = makeViewModel(analysis: analysis)

        // Should not crash and should return valid strings
        #expect(viewModel.formattedRepCount.contains("0"))
        #expect(!viewModel.formattedPeakVelocity.isEmpty)
        #expect(!viewModel.formattedAverageVelocity.isEmpty)
        #expect(!viewModel.formattedConsistency.isEmpty)
        #expect(!viewModel.formattedDisplacement.isEmpty)
        #expect(!viewModel.formattedDrift.isEmpty)
    }

    // MARK: - Export

    @Test("exportVideo returns nil when no video URL is set")
    func exportVideoReturnsNilWithoutURL() {
        let analysis = BarPathAnalysis(
            liftType: .squat,
            points: [],
            reps: [],
            metrics: AnalysisMetrics.calculate(from: []),
            videoURL: nil,
            duration: 0
        )
        let viewModel = makeViewModel(analysis: analysis)

        #expect(viewModel.exportVideo() == nil)
    }

    @Test("exportVideo returns URL when video URL is set")
    func exportVideoReturnsURLWhenSet() {
        let testURL = URL(fileURLWithPath: "/tmp/test.mp4")
        let analysis = BarPathAnalysis(
            liftType: .squat,
            points: [],
            reps: [],
            metrics: AnalysisMetrics.calculate(from: []),
            videoURL: testURL,
            duration: 0
        )
        let viewModel = makeViewModel(analysis: analysis)

        #expect(viewModel.exportVideo() == testURL)
    }

    // MARK: - Share Analysis

    @Test("shareAnalysis returns non-empty string")
    func shareAnalysisReturnsNonEmpty() {
        let analysis = TestData.makeAnalysis(repCount: 2)
        let viewModel = makeViewModel(analysis: analysis)

        let shareText = viewModel.shareAnalysis()
        #expect(!shareText.isEmpty)
    }

    // MARK: - Show Metrics Toggle

    @Test("showMetrics can be toggled")
    func showMetricsToggle() {
        let viewModel = makeViewModel()

        #expect(viewModel.showMetrics == true)

        viewModel.showMetrics = false
        #expect(viewModel.showMetrics == false)

        viewModel.showMetrics = true
        #expect(viewModel.showMetrics == true)
    }
}
