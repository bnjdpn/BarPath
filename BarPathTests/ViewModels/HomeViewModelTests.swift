import Testing
import Foundation
@testable import BarPath

@Suite("HomeViewModel Tests")
@MainActor
struct HomeViewModelTests {

    // MARK: - Load Recent

    @Test("Init automatically loads recent analyses from persistence")
    func initLoadsRecentAnalyses() {
        let persistence = MockPersistenceService()
        let analysis1 = TestData.makeAnalysis(liftType: .squat)
        let analysis2 = TestData.makeAnalysis(liftType: .deadlift)
        persistence.savedAnalyses = [analysis1, analysis2]

        let viewModel = HomeViewModel(persistence: persistence)

        #expect(viewModel.recentAnalyses.count == 2)
        #expect(persistence.loadAnalysesCallCount >= 1)
    }

    @Test("loadRecent refreshes the list from persistence")
    func loadRecentRefreshesList() {
        let persistence = MockPersistenceService()
        let viewModel = HomeViewModel(persistence: persistence)
        #expect(viewModel.recentAnalyses.isEmpty)

        // Add an analysis after init
        let analysis = TestData.makeAnalysis()
        persistence.savedAnalyses = [analysis]
        viewModel.loadRecent()

        #expect(viewModel.recentAnalyses.count == 1)
        #expect(viewModel.recentAnalyses.first?.id == analysis.id)
    }

    @Test("loadRecent returns analyses sorted by date descending")
    func loadRecentSortedByDate() {
        let persistence = MockPersistenceService()

        let older = BarPathAnalysis(
            date: Date(timeIntervalSince1970: 1000),
            liftType: .squat,
            points: [],
            reps: [],
            metrics: AnalysisMetrics.calculate(from: []),
            duration: 0
        )
        let newer = BarPathAnalysis(
            date: Date(timeIntervalSince1970: 2000),
            liftType: .deadlift,
            points: [],
            reps: [],
            metrics: AnalysisMetrics.calculate(from: []),
            duration: 0
        )
        persistence.savedAnalyses = [older, newer]

        let viewModel = HomeViewModel(persistence: persistence)

        #expect(viewModel.recentAnalyses.first?.liftType == .deadlift)
        #expect(viewModel.recentAnalyses.last?.liftType == .squat)
    }

    // MARK: - Delete Analysis

    @Test("deleteAnalysis removes analysis and refreshes list")
    func deleteAnalysisRemovesAndRefreshes() {
        let persistence = MockPersistenceService()
        let analysis = TestData.makeAnalysis()
        persistence.savedAnalyses = [analysis]

        let viewModel = HomeViewModel(persistence: persistence)
        #expect(viewModel.recentAnalyses.count == 1)

        viewModel.deleteAnalysis(id: analysis.id)

        #expect(persistence.deleteAnalysisCallCount == 1)
        #expect(viewModel.recentAnalyses.isEmpty)
    }

    @Test("deleteAnalysis with non-existent ID does not affect existing analyses")
    func deleteNonExistentAnalysis() {
        let persistence = MockPersistenceService()
        let analysis = TestData.makeAnalysis()
        persistence.savedAnalyses = [analysis]

        let viewModel = HomeViewModel(persistence: persistence)

        viewModel.deleteAnalysis(id: UUID())

        // The existing analysis should remain since MockPersistenceService
        // only removes matching IDs
        #expect(viewModel.recentAnalyses.count == 1)
    }

    @Test("deleteAnalysis only removes the targeted analysis")
    func deleteOnlyTargeted() {
        let persistence = MockPersistenceService()
        let analysis1 = TestData.makeAnalysis(liftType: .squat)
        let analysis2 = TestData.makeAnalysis(liftType: .deadlift)
        persistence.savedAnalyses = [analysis1, analysis2]

        let viewModel = HomeViewModel(persistence: persistence)

        viewModel.deleteAnalysis(id: analysis1.id)

        #expect(viewModel.recentAnalyses.count == 1)
        #expect(viewModel.recentAnalyses.first?.id == analysis2.id)
    }

    // MARK: - Empty State

    @Test("Empty state when no analyses exist")
    func emptyState() {
        let persistence = MockPersistenceService()
        let viewModel = HomeViewModel(persistence: persistence)

        #expect(viewModel.recentAnalyses.isEmpty)
    }

    // MARK: - Multiple Operations

    @Test("Multiple deletes leave correct remaining analyses")
    func multipleDeletes() {
        let persistence = MockPersistenceService()
        let analysis1 = TestData.makeAnalysis(liftType: .squat)
        let analysis2 = TestData.makeAnalysis(liftType: .deadlift)
        let analysis3 = TestData.makeAnalysis(liftType: .benchPress)
        persistence.savedAnalyses = [analysis1, analysis2, analysis3]

        let viewModel = HomeViewModel(persistence: persistence)
        #expect(viewModel.recentAnalyses.count == 3)

        viewModel.deleteAnalysis(id: analysis1.id)
        #expect(viewModel.recentAnalyses.count == 2)

        viewModel.deleteAnalysis(id: analysis3.id)
        #expect(viewModel.recentAnalyses.count == 1)
        #expect(viewModel.recentAnalyses.first?.id == analysis2.id)
    }

    @Test("loadRecent reflects external changes to persistence")
    func loadRecentReflectsExternalChanges() {
        let persistence = MockPersistenceService()
        let viewModel = HomeViewModel(persistence: persistence)
        #expect(viewModel.recentAnalyses.isEmpty)

        // Simulate external save (another part of the app saving data)
        let analysis = TestData.makeAnalysis()
        persistence.savedAnalyses = [analysis]

        viewModel.loadRecent()
        #expect(viewModel.recentAnalyses.count == 1)
    }
}
