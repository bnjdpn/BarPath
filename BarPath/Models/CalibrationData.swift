import Foundation

/// The method used to calibrate normalized coordinates to real-world measurements.
enum CalibrationMethod: String, Codable, Sendable {
    /// Calibration based on a known plate diameter (e.g., a standard 450 mm plate).
    case plateSize
    /// Calibration based on the user's known height visible in frame.
    case userHeight
    /// Manual calibration where the user provides a known reference distance.
    case manual
}

/// Calibration data for converting Vision's normalized coordinates into real-world meters.
struct CalibrationData: Codable, Sendable {

    // MARK: - Properties

    let method: CalibrationMethod
    let referenceValueMeters: Double
    let pixelsPerMeter: Double

    // MARK: - Initialization

    /// Creates calibration data from a known reference measurement.
    ///
    /// - Parameters:
    ///   - method: The calibration method used.
    ///   - referenceValueMeters: The real-world size of the reference object in meters.
    ///   - pixelsPerMeter: The number of pixels (in the video frame) that correspond to one meter.
    init(
        method: CalibrationMethod,
        referenceValueMeters: Double,
        pixelsPerMeter: Double
    ) {
        self.method = method
        self.referenceValueMeters = referenceValueMeters
        self.pixelsPerMeter = pixelsPerMeter
    }

    // MARK: - Conversion

    /// Converts a normalized distance (0-1 range) to real-world meters using the frame height
    /// as the reference dimension.
    ///
    /// - Parameters:
    ///   - distance: A normalized distance value (0-1, relative to frame dimensions).
    ///   - frameHeight: The pixel height of the video frame.
    /// - Returns: The equivalent distance in meters.
    func metersFromNormalized(_ distance: Double, frameHeight: Double) -> Double {
        guard pixelsPerMeter > 0 else { return 0 }
        let pixelDistance = distance * frameHeight
        return pixelDistance / pixelsPerMeter
    }
}
