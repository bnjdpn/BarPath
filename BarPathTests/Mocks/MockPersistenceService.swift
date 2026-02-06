import Foundation
@testable import BarPath

final class MockPersistenceService: DataStoring, @unchecked Sendable {

    // MARK: - Storage

    var savedAnalyses: [BarPathAnalysis] = []
    var savedSettings: AppSettings?

    // MARK: - Call Tracking

    var saveAnalysisCallCount = 0
    var loadAnalysesCallCount = 0
    var loadAnalysisByIdCallCount = 0
    var deleteAnalysisCallCount = 0
    var saveSettingsCallCount = 0
    var loadSettingsCallCount = 0

    var shouldThrowOnSave = false
    var saveError: Error = NSError(domain: "MockPersistence", code: -1)

    // MARK: - DataStoring

    func saveAnalysis(_ analysis: BarPathAnalysis) throws {
        saveAnalysisCallCount += 1
        if shouldThrowOnSave {
            throw saveError
        }
        // Replace existing or append
        if let existingIndex = savedAnalyses.firstIndex(where: { $0.id == analysis.id }) {
            savedAnalyses[existingIndex] = analysis
        } else {
            savedAnalyses.append(analysis)
        }
    }

    func loadAnalyses() -> [RecentAnalysis] {
        loadAnalysesCallCount += 1
        return savedAnalyses
            .map { RecentAnalysis(from: $0) }
            .sorted { $0.date > $1.date }
    }

    func loadAnalysis(id: UUID) -> BarPathAnalysis? {
        loadAnalysisByIdCallCount += 1
        return savedAnalyses.first { $0.id == id }
    }

    func deleteAnalysis(id: UUID) {
        deleteAnalysisCallCount += 1
        savedAnalyses.removeAll { $0.id == id }
    }

    func saveSettings(_ settings: AppSettings) {
        saveSettingsCallCount += 1
        savedSettings = settings
    }

    func loadSettings() -> AppSettings {
        loadSettingsCallCount += 1
        return savedSettings ?? .default
    }

    // MARK: - Helpers

    func reset() {
        savedAnalyses = []
        savedSettings = nil
        saveAnalysisCallCount = 0
        loadAnalysesCallCount = 0
        loadAnalysisByIdCallCount = 0
        deleteAnalysisCallCount = 0
        saveSettingsCallCount = 0
        loadSettingsCallCount = 0
        shouldThrowOnSave = false
    }
}
