import Testing
import Foundation
@testable import BarPath

@Suite("PersistenceService Tests")
struct PersistenceServiceTests {

    // MARK: - Helpers

    /// Creates a PersistenceService-like test harness that writes to a unique temporary directory,
    /// providing full isolation between tests.
    final class TestPersistenceHelper: DataStoring, @unchecked Sendable {
        private let analysesDirectoryURL: URL
        private let settingsURL: URL
        private let encoder = JSONEncoder()
        private let decoder = JSONDecoder()

        init() {
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("BarPathTests-\(UUID().uuidString)", isDirectory: true)
            self.analysesDirectoryURL = tempDir.appendingPathComponent("Analyses", isDirectory: true)
            self.settingsURL = tempDir.appendingPathComponent("settings.json")
            try? FileManager.default.createDirectory(
                at: analysesDirectoryURL,
                withIntermediateDirectories: true
            )
        }

        deinit {
            // Clean up temp directory
            let parentDir = analysesDirectoryURL.deletingLastPathComponent()
            try? FileManager.default.removeItem(at: parentDir)
        }

        func saveAnalysis(_ analysis: BarPathAnalysis) throws {
            let data = try encoder.encode(analysis)
            let fileURL = analysesDirectoryURL.appendingPathComponent("\(analysis.id.uuidString).json")
            try data.write(to: fileURL, options: .atomic)
        }

        func loadAnalyses() -> [RecentAnalysis] {
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: analysesDirectoryURL,
                includingPropertiesForKeys: nil
            ) else {
                return []
            }

            return files
                .filter { $0.pathExtension == "json" }
                .compactMap { url -> RecentAnalysis? in
                    guard let data = try? Data(contentsOf: url),
                          let analysis = try? decoder.decode(BarPathAnalysis.self, from: data) else {
                        return nil
                    }
                    return RecentAnalysis(from: analysis)
                }
                .sorted { $0.date > $1.date }
        }

        func loadAnalysis(id: UUID) -> BarPathAnalysis? {
            let fileURL = analysesDirectoryURL.appendingPathComponent("\(id.uuidString).json")
            guard let data = try? Data(contentsOf: fileURL) else { return nil }
            return try? decoder.decode(BarPathAnalysis.self, from: data)
        }

        func deleteAnalysis(id: UUID) {
            let fileURL = analysesDirectoryURL.appendingPathComponent("\(id.uuidString).json")
            try? FileManager.default.removeItem(at: fileURL)
        }

        func saveSettings(_ settings: AppSettings) {
            guard let data = try? encoder.encode(settings) else { return }
            try? data.write(to: settingsURL, options: .atomic)
        }

        func loadSettings() -> AppSettings {
            guard let data = try? Data(contentsOf: settingsURL),
                  let settings = try? decoder.decode(AppSettings.self, from: data) else {
                return .default
            }
            return settings
        }
    }

    // MARK: - Save and Load Analyses

    @Test("saveAnalysis and loadAnalyses round-trip")
    func saveAndLoadAnalyses() throws {
        let service = TestPersistenceHelper()
        let analysis = TestData.makeAnalysis()

        try service.saveAnalysis(analysis)

        let loaded = service.loadAnalyses()
        #expect(loaded.count == 1)
        #expect(loaded.first?.id == analysis.id)
        #expect(loaded.first?.liftType == analysis.liftType)
    }

    @Test("saveAnalysis stores multiple analyses")
    func saveMultipleAnalyses() throws {
        let service = TestPersistenceHelper()

        let analysis1 = TestData.makeAnalysis(liftType: .squat)
        let analysis2 = TestData.makeAnalysis(liftType: .deadlift)
        let analysis3 = TestData.makeAnalysis(liftType: .benchPress)

        try service.saveAnalysis(analysis1)
        try service.saveAnalysis(analysis2)
        try service.saveAnalysis(analysis3)

        let loaded = service.loadAnalyses()
        #expect(loaded.count == 3)

        let loadedIds = Set(loaded.map(\.id))
        #expect(loadedIds.contains(analysis1.id))
        #expect(loadedIds.contains(analysis2.id))
        #expect(loadedIds.contains(analysis3.id))
    }

    @Test("loadAnalysis by ID returns the correct analysis")
    func loadAnalysisById() throws {
        let service = TestPersistenceHelper()
        let analysis = TestData.makeAnalysis(notes: "Test note")

        try service.saveAnalysis(analysis)

        let loaded = service.loadAnalysis(id: analysis.id)
        #expect(loaded != nil)
        #expect(loaded?.id == analysis.id)
        #expect(loaded?.notes == "Test note")
        #expect(loaded?.liftType == .squat)
    }

    @Test("loadAnalysis with non-existent ID returns nil")
    func loadAnalysisNonExistentId() {
        let service = TestPersistenceHelper()
        let result = service.loadAnalysis(id: UUID())
        #expect(result == nil)
    }

    @Test("loadAnalyses returns empty array when no analyses saved")
    func loadAnalysesEmpty() {
        let service = TestPersistenceHelper()
        let loaded = service.loadAnalyses()
        #expect(loaded.isEmpty)
    }

    @Test("loadAnalyses returns analyses sorted by date descending")
    func loadAnalysesSortedByDate() throws {
        let service = TestPersistenceHelper()

        let oldDate = Date(timeIntervalSince1970: 1000)
        let midDate = Date(timeIntervalSince1970: 2000)
        let newDate = Date(timeIntervalSince1970: 3000)

        let oldAnalysis = BarPathAnalysis(
            date: oldDate,
            liftType: .squat,
            points: [],
            reps: [],
            metrics: AnalysisMetrics.calculate(from: []),
            duration: 0
        )
        let midAnalysis = BarPathAnalysis(
            date: midDate,
            liftType: .deadlift,
            points: [],
            reps: [],
            metrics: AnalysisMetrics.calculate(from: []),
            duration: 0
        )
        let newAnalysis = BarPathAnalysis(
            date: newDate,
            liftType: .benchPress,
            points: [],
            reps: [],
            metrics: AnalysisMetrics.calculate(from: []),
            duration: 0
        )

        // Save in non-chronological order
        try service.saveAnalysis(midAnalysis)
        try service.saveAnalysis(oldAnalysis)
        try service.saveAnalysis(newAnalysis)

        let loaded = service.loadAnalyses()
        #expect(loaded.count == 3)
        #expect(loaded[0].date == newDate)
        #expect(loaded[1].date == midDate)
        #expect(loaded[2].date == oldDate)
    }

    // MARK: - Delete Analysis

    @Test("deleteAnalysis removes the analysis")
    func deleteAnalysis() throws {
        let service = TestPersistenceHelper()
        let analysis = TestData.makeAnalysis()

        try service.saveAnalysis(analysis)
        #expect(service.loadAnalyses().count == 1)

        service.deleteAnalysis(id: analysis.id)
        #expect(service.loadAnalyses().isEmpty)
    }

    @Test("deleteAnalysis with non-existent ID does not crash")
    func deleteNonExistentAnalysis() {
        let service = TestPersistenceHelper()
        // Should not throw or crash
        service.deleteAnalysis(id: UUID())
    }

    @Test("deleteAnalysis only removes the targeted analysis")
    func deleteOnlyTargetedAnalysis() throws {
        let service = TestPersistenceHelper()
        let analysis1 = TestData.makeAnalysis(liftType: .squat)
        let analysis2 = TestData.makeAnalysis(liftType: .deadlift)

        try service.saveAnalysis(analysis1)
        try service.saveAnalysis(analysis2)

        service.deleteAnalysis(id: analysis1.id)

        let remaining = service.loadAnalyses()
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == analysis2.id)
    }

    // MARK: - Settings

    @Test("saveSettings and loadSettings round-trip")
    func saveAndLoadSettings() {
        let service = TestPersistenceHelper()
        let settings = AppSettings(
            preferredLiftType: .deadlift,
            showVelocityOverlay: false,
            showDriftLines: false,
            autoDetectReps: true,
            recordingFPS: .thirty,
            pathColor: .phase
        )

        service.saveSettings(settings)
        let loaded = service.loadSettings()

        #expect(loaded.preferredLiftType == .deadlift)
        #expect(loaded.showVelocityOverlay == false)
        #expect(loaded.showDriftLines == false)
        #expect(loaded.autoDetectReps == true)
        #expect(loaded.recordingFPS == .thirty)
        #expect(loaded.pathColor == .phase)
    }

    @Test("loadSettings returns defaults when none saved")
    func loadSettingsReturnsDefaults() {
        let service = TestPersistenceHelper()
        let settings = service.loadSettings()

        #expect(settings.preferredLiftType == .squat)
        #expect(settings.showVelocityOverlay == true)
        #expect(settings.recordingFPS == .sixty)
        #expect(settings.pathColor == .velocity)
    }

    @Test("saveSettings overwrites previous settings")
    func saveSettingsOverwrites() {
        let service = TestPersistenceHelper()

        let settings1 = AppSettings(preferredLiftType: .squat)
        service.saveSettings(settings1)
        #expect(service.loadSettings().preferredLiftType == .squat)

        let settings2 = AppSettings(preferredLiftType: .benchPress)
        service.saveSettings(settings2)
        #expect(service.loadSettings().preferredLiftType == .benchPress)
    }

    @Test("Settings with calibration data round-trip correctly")
    func settingsWithCalibrationRoundTrip() {
        let service = TestPersistenceHelper()
        let calibration = TestData.makeCalibration()
        let settings = AppSettings(calibrationData: calibration)

        service.saveSettings(settings)
        let loaded = service.loadSettings()

        #expect(loaded.calibrationData != nil)
        #expect(loaded.calibrationData?.method == .plateSize)
        #expect(loaded.calibrationData?.referenceValueMeters == 0.45)
        #expect(loaded.calibrationData?.pixelsPerMeter == 500.0)
    }
}
