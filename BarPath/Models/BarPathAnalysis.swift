import Foundation

/// The complete result of a bar path analysis session, containing all tracked points,
/// detected reps, computed metrics, and associated media.
struct BarPathAnalysis: Codable, Sendable, Identifiable {

    // MARK: - Properties

    let id: UUID
    let date: Date
    let liftType: LiftType
    let points: [BarPathPoint]
    let reps: [RepSegment]
    let metrics: AnalysisMetrics
    let videoURL: URL?
    let thumbnailData: Data?
    let duration: TimeInterval
    var notes: String

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        liftType: LiftType,
        points: [BarPathPoint],
        reps: [RepSegment],
        metrics: AnalysisMetrics,
        videoURL: URL? = nil,
        thumbnailData: Data? = nil,
        duration: TimeInterval,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.liftType = liftType
        self.points = points
        self.reps = reps
        self.metrics = metrics
        self.videoURL = videoURL
        self.thumbnailData = thumbnailData
        self.duration = duration
        self.notes = notes
    }
}
