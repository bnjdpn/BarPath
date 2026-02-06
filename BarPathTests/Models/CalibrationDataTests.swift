import Testing
import Foundation
@testable import BarPath

@Suite("CalibrationData Tests")
struct CalibrationDataTests {

    // MARK: - metersFromNormalized with Plate Size Method

    @Test("metersFromNormalized converts correctly with plate size calibration")
    func metersFromNormalizedWithPlateSize() {
        let calibration = CalibrationData(
            method: .plateSize,
            referenceValueMeters: 0.45,
            pixelsPerMeter: 500.0
        )

        // A normalized distance of 0.5 with a frame height of 1920 pixels:
        // pixelDistance = 0.5 * 1920 = 960
        // meters = 960 / 500 = 1.92
        let meters = calibration.metersFromNormalized(0.5, frameHeight: 1920.0)
        #expect(abs(meters - 1.92) < 0.001)
    }

    @Test("metersFromNormalized returns zero for zero distance")
    func metersFromNormalizedZeroDistance() {
        let calibration = TestData.makeCalibration()

        let meters = calibration.metersFromNormalized(0.0, frameHeight: 1080.0)
        #expect(meters == 0.0)
    }

    @Test("metersFromNormalized with full frame distance")
    func metersFromNormalizedFullFrame() {
        let calibration = CalibrationData(
            method: .plateSize,
            referenceValueMeters: 0.45,
            pixelsPerMeter: 1000.0
        )

        // normalized distance 1.0 with frame height 1000 pixels = 1000/1000 = 1.0 meter
        let meters = calibration.metersFromNormalized(1.0, frameHeight: 1000.0)
        #expect(abs(meters - 1.0) < 0.001)
    }

    // MARK: - metersFromNormalized with User Height Method

    @Test("metersFromNormalized converts correctly with user height calibration")
    func metersFromNormalizedWithUserHeight() {
        let calibration = CalibrationData(
            method: .userHeight,
            referenceValueMeters: 1.80,
            pixelsPerMeter: 600.0
        )

        // Normalized distance of 0.3, frame height 1080:
        // pixelDistance = 0.3 * 1080 = 324
        // meters = 324 / 600 = 0.54
        let meters = calibration.metersFromNormalized(0.3, frameHeight: 1080.0)
        #expect(abs(meters - 0.54) < 0.001)
    }

    @Test("metersFromNormalized with manual calibration method")
    func metersFromNormalizedWithManualCalibration() {
        let calibration = CalibrationData(
            method: .manual,
            referenceValueMeters: 1.0,
            pixelsPerMeter: 800.0
        )

        let meters = calibration.metersFromNormalized(0.25, frameHeight: 1600.0)
        // pixelDistance = 0.25 * 1600 = 400
        // meters = 400 / 800 = 0.5
        #expect(abs(meters - 0.5) < 0.001)
    }

    // MARK: - Zero Reference Value Edge Case

    @Test("metersFromNormalized returns zero when pixelsPerMeter is zero")
    func metersFromNormalizedWithZeroPixelsPerMeter() {
        let calibration = CalibrationData(
            method: .plateSize,
            referenceValueMeters: 0.45,
            pixelsPerMeter: 0.0
        )

        let meters = calibration.metersFromNormalized(0.5, frameHeight: 1920.0)
        #expect(meters == 0.0)
    }

    @Test("metersFromNormalized with very small pixelsPerMeter")
    func metersFromNormalizedWithSmallPixelsPerMeter() {
        let calibration = CalibrationData(
            method: .plateSize,
            referenceValueMeters: 0.45,
            pixelsPerMeter: 0.001
        )

        // Should not crash; result will be very large
        let meters = calibration.metersFromNormalized(0.5, frameHeight: 1920.0)
        #expect(meters > 0)
    }

    @Test("metersFromNormalized with zero frame height")
    func metersFromNormalizedWithZeroFrameHeight() {
        let calibration = TestData.makeCalibration()

        let meters = calibration.metersFromNormalized(0.5, frameHeight: 0.0)
        #expect(meters == 0.0)
    }

    // MARK: - Codable

    @Test("Codable round-trip preserves all calibration data")
    func codableRoundTrip() throws {
        let original = CalibrationData(
            method: .plateSize,
            referenceValueMeters: 0.45,
            pixelsPerMeter: 500.0
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CalibrationData.self, from: data)

        #expect(decoded.method == original.method)
        #expect(decoded.referenceValueMeters == original.referenceValueMeters)
        #expect(decoded.pixelsPerMeter == original.pixelsPerMeter)
    }

    @Test("Codable round-trip for userHeight method")
    func codableRoundTripUserHeight() throws {
        let original = CalibrationData(
            method: .userHeight,
            referenceValueMeters: 1.85,
            pixelsPerMeter: 650.0
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CalibrationData.self, from: data)

        #expect(decoded.method == .userHeight)
        #expect(decoded.referenceValueMeters == 1.85)
        #expect(decoded.pixelsPerMeter == 650.0)
    }

    @Test("Codable round-trip for manual method")
    func codableRoundTripManual() throws {
        let original = CalibrationData(
            method: .manual,
            referenceValueMeters: 1.0,
            pixelsPerMeter: 800.0
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CalibrationData.self, from: data)

        #expect(decoded.method == .manual)
    }

    // MARK: - CalibrationMethod Codable

    @Test("CalibrationMethod Codable round-trip for all cases")
    func calibrationMethodCodableRoundTrip() throws {
        let methods: [CalibrationMethod] = [.plateSize, .userHeight, .manual]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for method in methods {
            let data = try encoder.encode(method)
            let decoded = try decoder.decode(CalibrationMethod.self, from: data)
            #expect(decoded == method)
        }
    }
}
