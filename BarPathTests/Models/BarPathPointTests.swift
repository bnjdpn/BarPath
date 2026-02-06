import Testing
import Foundation
import CoreGraphics
@testable import BarPath

@Suite("BarPathPoint Tests")
struct BarPathPointTests {

    // MARK: - Initialization

    @Test("Initialization stores all properties correctly")
    func initializationWithValidValues() {
        let id = UUID()
        let point = BarPathPoint(id: id, x: 0.25, y: 0.75, timestamp: 1.5, confidence: 0.95)

        #expect(point.id == id)
        #expect(point.x == 0.25)
        #expect(point.y == 0.75)
        #expect(point.timestamp == 1.5)
        #expect(point.confidence == 0.95)
    }

    @Test("Initialization with default UUID generates unique IDs")
    func initializationGeneratesUniqueIDs() {
        let point1 = BarPathPoint(x: 0.5, y: 0.5, timestamp: 0, confidence: 0.9)
        let point2 = BarPathPoint(x: 0.5, y: 0.5, timestamp: 0, confidence: 0.9)

        #expect(point1.id != point2.id)
    }

    @Test("Initialization with zero values")
    func initializationWithZeroValues() {
        let point = BarPathPoint(x: 0.0, y: 0.0, timestamp: 0.0, confidence: 0.0)

        #expect(point.x == 0.0)
        #expect(point.y == 0.0)
        #expect(point.timestamp == 0.0)
        #expect(point.confidence == 0.0)
    }

    @Test("Initialization with boundary values at edges of normalized range")
    func initializationWithBoundaryValues() {
        let point = BarPathPoint(x: 1.0, y: 1.0, timestamp: 100.0, confidence: 1.0)

        #expect(point.x == 1.0)
        #expect(point.y == 1.0)
        #expect(point.confidence == 1.0)
    }

    // MARK: - cgPoint Computed Property

    @Test("cgPoint returns correct CGPoint from x and y")
    func cgPointConversion() {
        let point = BarPathPoint(x: 0.3, y: 0.7, timestamp: 0, confidence: 0.9)
        let cgPoint = point.cgPoint

        #expect(cgPoint.x == 0.3)
        #expect(cgPoint.y == 0.7)
    }

    @Test("cgPoint at origin returns CGPoint.zero")
    func cgPointAtOrigin() {
        let point = BarPathPoint(x: 0.0, y: 0.0, timestamp: 0, confidence: 0.9)

        #expect(point.cgPoint == CGPoint.zero)
    }

    @Test("cgPoint at maximum returns (1, 1)")
    func cgPointAtMax() {
        let point = BarPathPoint(x: 1.0, y: 1.0, timestamp: 0, confidence: 0.9)

        #expect(point.cgPoint == CGPoint(x: 1.0, y: 1.0))
    }

    // MARK: - Codable

    @Test("Codable round-trip preserves all properties")
    func codableRoundTrip() throws {
        let original = BarPathPoint(x: 0.42, y: 0.58, timestamp: 3.14, confidence: 0.87)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BarPathPoint.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.x == original.x)
        #expect(decoded.y == original.y)
        #expect(decoded.timestamp == original.timestamp)
        #expect(decoded.confidence == original.confidence)
    }

    @Test("Codable round-trip with extreme values")
    func codableRoundTripExtremeValues() throws {
        let original = BarPathPoint(x: 0.0, y: 1.0, timestamp: 99999.999, confidence: 0.001)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BarPathPoint.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.x == original.x)
        #expect(decoded.y == original.y)
        #expect(decoded.timestamp == original.timestamp)
        #expect(decoded.confidence == original.confidence)
    }

    @Test("Encoding produces valid JSON")
    func encodingProducesValidJSON() throws {
        let point = BarPathPoint(x: 0.5, y: 0.5, timestamp: 1.0, confidence: 0.9)

        let data = try JSONEncoder().encode(point)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json != nil)
        #expect(json?["x"] as? Double == 0.5)
        #expect(json?["y"] as? Double == 0.5)
    }

    // MARK: - Equatable

    @Test("Points with same ID are equal")
    func equatableWithSameID() {
        let id = UUID()
        let point1 = BarPathPoint(id: id, x: 0.5, y: 0.5, timestamp: 1.0, confidence: 0.9)
        let point2 = BarPathPoint(id: id, x: 0.5, y: 0.5, timestamp: 1.0, confidence: 0.9)

        #expect(point1 == point2)
    }

    @Test("Points with different IDs are not equal")
    func equatableWithDifferentIDs() {
        let point1 = BarPathPoint(x: 0.5, y: 0.5, timestamp: 1.0, confidence: 0.9)
        let point2 = BarPathPoint(x: 0.5, y: 0.5, timestamp: 1.0, confidence: 0.9)

        #expect(point1 != point2)
    }

    @Test("Points with same ID but different values are not equal")
    func equatableWithDifferentValues() {
        let id = UUID()
        let point1 = BarPathPoint(id: id, x: 0.5, y: 0.5, timestamp: 1.0, confidence: 0.9)
        let point2 = BarPathPoint(id: id, x: 0.6, y: 0.5, timestamp: 1.0, confidence: 0.9)

        #expect(point1 != point2)
    }
}
