import Foundation

/// A lightweight summary of a bar path analysis, suitable for display in history lists
/// without loading the full point data.
struct RecentAnalysis: Codable, Sendable, Identifiable {

    // MARK: - Properties

    let id: UUID
    let date: Date
    let liftType: LiftType
    let repCount: Int
    let peakVelocity: Double
    let thumbnailData: Data?

    // MARK: - Initialization

    /// Creates a lightweight summary from a full `BarPathAnalysis`.
    ///
    /// - Parameter analysis: The complete analysis to summarize.
    init(from analysis: BarPathAnalysis) {
        self.id = analysis.id
        self.date = analysis.date
        self.liftType = analysis.liftType
        self.repCount = analysis.metrics.repCount
        self.peakVelocity = analysis.metrics.peakVelocity
        self.thumbnailData = analysis.thumbnailData
    }

    /// Memberwise initializer for direct construction or decoding.
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        liftType: LiftType,
        repCount: Int,
        peakVelocity: Double,
        thumbnailData: Data? = nil
    ) {
        self.id = id
        self.date = date
        self.liftType = liftType
        self.repCount = repCount
        self.peakVelocity = peakVelocity
        self.thumbnailData = thumbnailData
    }
}
