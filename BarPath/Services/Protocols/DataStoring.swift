import Foundation

/// Protocol abstracting data persistence operations.
/// Enables dependency injection and testability by decoupling storage
/// implementation from consumers.
protocol DataStoring: Sendable {

    /// Persists a complete bar path analysis.
    ///
    /// - Parameter analysis: The analysis to save.
    /// - Throws: An error if encoding or writing fails.
    func saveAnalysis(_ analysis: BarPathAnalysis) throws

    /// Loads lightweight summaries of all stored analyses, sorted by date descending.
    ///
    /// - Returns: An array of `RecentAnalysis` summaries.
    func loadAnalyses() -> [RecentAnalysis]

    /// Loads a full analysis by its identifier.
    ///
    /// - Parameter id: The unique identifier of the analysis.
    /// - Returns: The complete `BarPathAnalysis`, or `nil` if not found.
    func loadAnalysis(id: UUID) -> BarPathAnalysis?

    /// Deletes a stored analysis by its identifier.
    ///
    /// - Parameter id: The unique identifier of the analysis to remove.
    func deleteAnalysis(id: UUID)

    /// Persists the user's application settings.
    ///
    /// - Parameter settings: The settings to save.
    func saveSettings(_ settings: AppSettings)

    /// Loads the user's application settings.
    ///
    /// - Returns: The stored `AppSettings`, or defaults if none are saved.
    func loadSettings() -> AppSettings
}
