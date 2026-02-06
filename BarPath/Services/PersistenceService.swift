import Foundation

/// UserDefaults-based persistence service conforming to `DataStoring`.
///
/// Analyses are stored as JSON-encoded data in `UserDefaults` with a `barpath_` key prefix.
/// A separate index of recent analysis summaries is maintained, capped at 20 entries.
/// Settings are stored under their own key.
final class PersistenceService: DataStoring, @unchecked Sendable {

    // MARK: - Constants

    private enum Keys {
        static let recentAnalysesIndex = "barpath_recent_analyses"
        static let settings = "barpath_settings"
        static func analysis(id: UUID) -> String { "barpath_analysis_\(id.uuidString)" }
    }

    /// Maximum number of recent analysis summaries to retain.
    private static let maxRecentAnalyses = 20

    // MARK: - Properties

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: - Initialization

    /// Creates a persistence service backed by the given `UserDefaults` instance.
    ///
    /// - Parameter defaults: The `UserDefaults` store to use. Defaults to `.standard`.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    // MARK: - DataStoring: Analyses

    func saveAnalysis(_ analysis: BarPathAnalysis) throws {
        let data = try encoder.encode(analysis)
        defaults.set(data, forKey: Keys.analysis(id: analysis.id))

        // Update the recent analyses index.
        var recentList = loadAnalyses()

        // Remove any existing entry for this analysis to avoid duplicates.
        recentList.removeAll { $0.id == analysis.id }

        // Insert the new summary at the front.
        let summary = RecentAnalysis(from: analysis)
        recentList.insert(summary, at: 0)

        // Trim to the maximum allowed count.
        if recentList.count > Self.maxRecentAnalyses {
            let removed = recentList.suffix(from: Self.maxRecentAnalyses)
            for entry in removed {
                defaults.removeObject(forKey: Keys.analysis(id: entry.id))
            }
            recentList = Array(recentList.prefix(Self.maxRecentAnalyses))
        }

        // Persist the updated index.
        if let indexData = try? encoder.encode(recentList) {
            defaults.set(indexData, forKey: Keys.recentAnalysesIndex)
        }
    }

    func loadAnalyses() -> [RecentAnalysis] {
        guard let data = defaults.data(forKey: Keys.recentAnalysesIndex),
              let analyses = try? decoder.decode([RecentAnalysis].self, from: data) else {
            return []
        }
        return analyses.sorted { $0.date > $1.date }
    }

    func loadAnalysis(id: UUID) -> BarPathAnalysis? {
        guard let data = defaults.data(forKey: Keys.analysis(id: id)) else {
            return nil
        }
        return try? decoder.decode(BarPathAnalysis.self, from: data)
    }

    func deleteAnalysis(id: UUID) {
        defaults.removeObject(forKey: Keys.analysis(id: id))

        // Remove from the recent analyses index.
        var recentList = loadAnalyses()
        recentList.removeAll { $0.id == id }

        if let indexData = try? encoder.encode(recentList) {
            defaults.set(indexData, forKey: Keys.recentAnalysesIndex)
        }
    }

    // MARK: - DataStoring: Settings

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        defaults.set(data, forKey: Keys.settings)
    }

    func loadSettings() -> AppSettings {
        guard let data = defaults.data(forKey: Keys.settings),
              let settings = try? decoder.decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }
}
