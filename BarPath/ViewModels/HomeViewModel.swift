import SwiftUI

/// ViewModel for the home screen, managing the list of recent analyses
/// and coordinating deletion actions with the persistence layer.
@Observable
@MainActor
final class HomeViewModel {

    // MARK: - Properties

    var recentAnalyses: [RecentAnalysis] = []

    private let persistence: DataStoring

    // MARK: - Initialization

    init(persistence: DataStoring = PersistenceService()) {
        self.persistence = persistence
        loadRecent()
    }

    // MARK: - Actions

    /// Reloads the list of recent analyses from persistence.
    func loadRecent() {
        recentAnalyses = persistence.loadAnalyses()
    }

    /// Deletes an analysis by identifier and refreshes the list.
    ///
    /// - Parameter id: The unique identifier of the analysis to remove.
    func deleteAnalysis(id: UUID) {
        persistence.deleteAnalysis(id: id)
        loadRecent()
    }
}
