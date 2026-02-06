import Testing
import Foundation
@testable import BarPath

@Suite("RepSegment Tests")
struct RepSegmentTests {

    // MARK: - Initialization

    @Test("Initialization stores all properties correctly")
    func initializationWithValidValues() {
        let id = UUID()
        let rep = RepSegment(
            id: id,
            repNumber: 1,
            startIndex: 0,
            endIndex: 60,
            concentricStartIndex: 30,
            peakVelocity: 1.5,
            averageVelocity: 0.8,
            verticalDisplacement: 0.3,
            horizontalDrift: 0.02,
            duration: 2.0
        )

        #expect(rep.id == id)
        #expect(rep.repNumber == 1)
        #expect(rep.startIndex == 0)
        #expect(rep.endIndex == 60)
        #expect(rep.concentricStartIndex == 30)
        #expect(rep.peakVelocity == 1.5)
        #expect(rep.averageVelocity == 0.8)
        #expect(rep.verticalDisplacement == 0.3)
        #expect(rep.horizontalDrift == 0.02)
        #expect(rep.duration == 2.0)
    }

    @Test("Default UUID is generated when not provided")
    func defaultUUIDGeneration() {
        let rep = TestData.makeRepSegment()
        #expect(rep.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    // MARK: - Computed Durations

    @Test("Concentric duration is proportional to concentric indices")
    func concentricDurationCalculation() {
        // startIndex=0, endIndex=100, concentricStartIndex=60
        // Total indices = 100, concentric indices = 100 - 60 = 40
        // Concentric duration = 4.0 * 40/100 = 1.6
        let rep = RepSegment(
            repNumber: 1,
            startIndex: 0,
            endIndex: 100,
            concentricStartIndex: 60,
            peakVelocity: 1.0,
            averageVelocity: 0.5,
            verticalDisplacement: 0.3,
            horizontalDrift: 0.02,
            duration: 4.0
        )

        #expect(rep.concentricDuration == 1.6)
    }

    @Test("Eccentric duration is proportional to eccentric indices")
    func eccentricDurationCalculation() {
        // startIndex=0, endIndex=100, concentricStartIndex=60
        // Total indices = 100, eccentric indices = 60 - 0 = 60
        // Eccentric duration = 4.0 * 60/100 = 2.4
        let rep = RepSegment(
            repNumber: 1,
            startIndex: 0,
            endIndex: 100,
            concentricStartIndex: 60,
            peakVelocity: 1.0,
            averageVelocity: 0.5,
            verticalDisplacement: 0.3,
            horizontalDrift: 0.02,
            duration: 4.0
        )

        #expect(rep.eccentricDuration == 2.4)
    }

    @Test("Concentric plus eccentric equals total duration")
    func concentricPlusEccentricEqualsTotal() {
        let rep = RepSegment(
            repNumber: 1,
            startIndex: 10,
            endIndex: 90,
            concentricStartIndex: 50,
            peakVelocity: 1.0,
            averageVelocity: 0.5,
            verticalDisplacement: 0.3,
            horizontalDrift: 0.02,
            duration: 3.0
        )

        let total = rep.concentricDuration + rep.eccentricDuration
        #expect(abs(total - rep.duration) < 0.0001)
    }

    @Test("Durations are zero when start equals end index")
    func zeroDurationWhenStartEqualsEnd() {
        let rep = RepSegment(
            repNumber: 1,
            startIndex: 50,
            endIndex: 50,
            concentricStartIndex: 50,
            peakVelocity: 0,
            averageVelocity: 0,
            verticalDisplacement: 0,
            horizontalDrift: 0,
            duration: 0
        )

        #expect(rep.concentricDuration == 0)
        #expect(rep.eccentricDuration == 0)
    }

    @Test("Concentric at start means full concentric, no eccentric")
    func concentricAtStartIndex() {
        // concentricStartIndex == startIndex means the concentric phase is the entire rep
        let rep = RepSegment(
            repNumber: 1,
            startIndex: 0,
            endIndex: 60,
            concentricStartIndex: 0,
            peakVelocity: 1.0,
            averageVelocity: 0.5,
            verticalDisplacement: 0.3,
            horizontalDrift: 0.02,
            duration: 2.0
        )

        #expect(rep.concentricDuration == 2.0)
        #expect(rep.eccentricDuration == 0.0)
    }

    @Test("Concentric at end means full eccentric, no concentric")
    func concentricAtEndIndex() {
        let rep = RepSegment(
            repNumber: 1,
            startIndex: 0,
            endIndex: 60,
            concentricStartIndex: 60,
            peakVelocity: 1.0,
            averageVelocity: 0.5,
            verticalDisplacement: 0.3,
            horizontalDrift: 0.02,
            duration: 2.0
        )

        #expect(rep.concentricDuration == 0.0)
        #expect(rep.eccentricDuration == 2.0)
    }

    // MARK: - Codable

    @Test("Codable round-trip preserves all properties")
    func codableRoundTrip() throws {
        let original = TestData.makeRepSegment(
            repNumber: 3,
            startIndex: 120,
            endIndex: 180,
            concentricStartIndex: 150,
            peakVelocity: 2.1,
            averageVelocity: 1.05,
            verticalDisplacement: 0.35,
            horizontalDrift: 0.04,
            duration: 2.5
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RepSegment.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.repNumber == original.repNumber)
        #expect(decoded.startIndex == original.startIndex)
        #expect(decoded.endIndex == original.endIndex)
        #expect(decoded.concentricStartIndex == original.concentricStartIndex)
        #expect(decoded.peakVelocity == original.peakVelocity)
        #expect(decoded.averageVelocity == original.averageVelocity)
        #expect(decoded.verticalDisplacement == original.verticalDisplacement)
        #expect(decoded.horizontalDrift == original.horizontalDrift)
        #expect(decoded.duration == original.duration)
    }

    @Test("Codable round-trip preserves computed properties")
    func codablePreservesComputedProperties() throws {
        let original = RepSegment(
            repNumber: 1,
            startIndex: 0,
            endIndex: 80,
            concentricStartIndex: 40,
            peakVelocity: 1.0,
            averageVelocity: 0.5,
            verticalDisplacement: 0.3,
            horizontalDrift: 0.02,
            duration: 3.0
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RepSegment.self, from: data)

        #expect(decoded.concentricDuration == original.concentricDuration)
        #expect(decoded.eccentricDuration == original.eccentricDuration)
    }
}
