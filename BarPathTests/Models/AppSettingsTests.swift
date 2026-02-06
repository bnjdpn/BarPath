import Testing
import Foundation
@testable import BarPath

@Suite("AppSettings Tests")
struct AppSettingsTests {

    // MARK: - Default Values

    @Test("Default settings have expected values")
    func defaultValues() {
        let settings = AppSettings()

        #expect(settings.preferredLiftType == .squat)
        #expect(settings.calibrationData == nil)
        #expect(settings.showVelocityOverlay == true)
        #expect(settings.showDriftLines == true)
        #expect(settings.autoDetectReps == true)
        #expect(settings.recordingFPS == .sixty)
        #expect(settings.pathColor == .velocity)
    }

    @Test("Static default property matches init defaults")
    func staticDefaultMatchesInitDefaults() {
        let defaultSettings = AppSettings.default
        let initSettings = AppSettings()

        #expect(defaultSettings.preferredLiftType == initSettings.preferredLiftType)
        #expect(defaultSettings.showVelocityOverlay == initSettings.showVelocityOverlay)
        #expect(defaultSettings.showDriftLines == initSettings.showDriftLines)
        #expect(defaultSettings.autoDetectReps == initSettings.autoDetectReps)
        #expect(defaultSettings.recordingFPS == initSettings.recordingFPS)
        #expect(defaultSettings.pathColor == initSettings.pathColor)
    }

    // MARK: - Custom Values

    @Test("Custom initialization overrides defaults")
    func customInitialization() {
        let calibration = TestData.makeCalibration()
        let settings = AppSettings(
            preferredLiftType: .deadlift,
            calibrationData: calibration,
            showVelocityOverlay: false,
            showDriftLines: false,
            autoDetectReps: false,
            recordingFPS: .thirty,
            pathColor: .fixed
        )

        #expect(settings.preferredLiftType == .deadlift)
        #expect(settings.calibrationData != nil)
        #expect(settings.showVelocityOverlay == false)
        #expect(settings.showDriftLines == false)
        #expect(settings.autoDetectReps == false)
        #expect(settings.recordingFPS == .thirty)
        #expect(settings.pathColor == .fixed)
    }

    // MARK: - Codable

    @Test("Codable round-trip preserves all settings")
    func codableRoundTrip() throws {
        let calibration = TestData.makeCalibration()
        let original = AppSettings(
            preferredLiftType: .overheadPress,
            calibrationData: calibration,
            showVelocityOverlay: false,
            showDriftLines: true,
            autoDetectReps: false,
            recordingFPS: .thirty,
            pathColor: .phase
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        #expect(decoded.preferredLiftType == original.preferredLiftType)
        #expect(decoded.calibrationData?.method == original.calibrationData?.method)
        #expect(decoded.calibrationData?.referenceValueMeters == original.calibrationData?.referenceValueMeters)
        #expect(decoded.calibrationData?.pixelsPerMeter == original.calibrationData?.pixelsPerMeter)
        #expect(decoded.showVelocityOverlay == original.showVelocityOverlay)
        #expect(decoded.showDriftLines == original.showDriftLines)
        #expect(decoded.autoDetectReps == original.autoDetectReps)
        #expect(decoded.recordingFPS == original.recordingFPS)
        #expect(decoded.pathColor == original.pathColor)
    }

    @Test("Codable round-trip with nil calibrationData")
    func codableRoundTripNilCalibration() throws {
        let original = AppSettings()

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        #expect(decoded.calibrationData == nil)
    }

    // MARK: - RecordingFPS

    @Test("RecordingFPS has all expected cases")
    func recordingFPSCases() {
        let allCases = RecordingFPS.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.thirty))
        #expect(allCases.contains(.sixty))
    }

    @Test("RecordingFPS raw values are correct")
    func recordingFPSRawValues() {
        #expect(RecordingFPS.thirty.rawValue == 30)
        #expect(RecordingFPS.sixty.rawValue == 60)
    }

    @Test("RecordingFPS displayNames are non-empty")
    func recordingFPSDisplayNames() {
        for fps in RecordingFPS.allCases {
            #expect(!fps.displayName.isEmpty, "displayName should not be empty for \(fps)")
        }
    }

    @Test("RecordingFPS Codable round-trip")
    func recordingFPSCodableRoundTrip() throws {
        for fps in RecordingFPS.allCases {
            let data = try JSONEncoder().encode(fps)
            let decoded = try JSONDecoder().decode(RecordingFPS.self, from: data)
            #expect(decoded == fps)
        }
    }

    // MARK: - PathColorOption

    @Test("PathColorOption has all expected cases")
    func pathColorOptionCases() {
        let allCases = PathColorOption.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.velocity))
        #expect(allCases.contains(.fixed))
        #expect(allCases.contains(.phase))
    }

    @Test("PathColorOption raw values are correct strings")
    func pathColorOptionRawValues() {
        #expect(PathColorOption.velocity.rawValue == "velocity")
        #expect(PathColorOption.fixed.rawValue == "fixed")
        #expect(PathColorOption.phase.rawValue == "phase")
    }

    @Test("PathColorOption displayNames are non-empty")
    func pathColorOptionDisplayNames() {
        for option in PathColorOption.allCases {
            #expect(!option.displayName.isEmpty, "displayName should not be empty for \(option)")
        }
    }

    @Test("PathColorOption Codable round-trip")
    func pathColorOptionCodableRoundTrip() throws {
        for option in PathColorOption.allCases {
            let data = try JSONEncoder().encode(option)
            let decoded = try JSONDecoder().decode(PathColorOption.self, from: data)
            #expect(decoded == option)
        }
    }

    // MARK: - Mutability

    @Test("Settings properties can be mutated")
    func settingsAreMutable() {
        var settings = AppSettings()

        settings.preferredLiftType = .benchPress
        settings.showVelocityOverlay = false
        settings.showDriftLines = false
        settings.autoDetectReps = false

        #expect(settings.preferredLiftType == .benchPress)
        #expect(settings.showVelocityOverlay == false)
        #expect(settings.showDriftLines == false)
        #expect(settings.autoDetectReps == false)
    }
}
