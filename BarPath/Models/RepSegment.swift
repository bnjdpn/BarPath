import Foundation

/// Represents an individual rep within a set, defined by index ranges into the parent points array.
struct RepSegment: Codable, Sendable, Identifiable {

    // MARK: - Properties

    let id: UUID
    let repNumber: Int
    let startIndex: Int
    let endIndex: Int
    let concentricStartIndex: Int
    let peakVelocity: Double
    let averageVelocity: Double
    let verticalDisplacement: Double
    let horizontalDrift: Double
    let duration: TimeInterval

    // MARK: - Computed Properties

    /// Duration of the concentric (lifting) phase, estimated by index proportion of the total duration.
    var concentricDuration: TimeInterval {
        let totalIndices = endIndex - startIndex
        guard totalIndices > 0 else { return 0 }
        let concentricIndices = endIndex - concentricStartIndex
        return duration * Double(concentricIndices) / Double(totalIndices)
    }

    /// Duration of the eccentric (lowering) phase, estimated by index proportion of the total duration.
    var eccentricDuration: TimeInterval {
        let totalIndices = endIndex - startIndex
        guard totalIndices > 0 else { return 0 }
        let eccentricIndices = concentricStartIndex - startIndex
        return duration * Double(eccentricIndices) / Double(totalIndices)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        repNumber: Int,
        startIndex: Int,
        endIndex: Int,
        concentricStartIndex: Int,
        peakVelocity: Double,
        averageVelocity: Double,
        verticalDisplacement: Double,
        horizontalDrift: Double,
        duration: TimeInterval
    ) {
        self.id = id
        self.repNumber = repNumber
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.concentricStartIndex = concentricStartIndex
        self.peakVelocity = peakVelocity
        self.averageVelocity = averageVelocity
        self.verticalDisplacement = verticalDisplacement
        self.horizontalDrift = horizontalDrift
        self.duration = duration
    }
}
