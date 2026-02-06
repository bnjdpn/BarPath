import Testing
import Foundation
import SwiftUI
@testable import BarPath

@Suite("LiftType Tests")
struct LiftTypeTests {

    // MARK: - Display Name

    @Test("All lift types have a non-empty displayName")
    func allCasesHaveDisplayName() {
        for liftType in LiftType.allCases {
            #expect(!liftType.displayName.isEmpty, "displayName should not be empty for \(liftType)")
        }
    }

    @Test("Each lift type has a unique displayName")
    func displayNamesAreUnique() {
        let names = LiftType.allCases.map(\.displayName)
        let uniqueNames = Set(names)
        #expect(uniqueNames.count == names.count, "All display names should be unique")
    }

    // MARK: - Icon

    @Test("All lift types have a non-empty icon string")
    func allCasesHaveIcon() {
        for liftType in LiftType.allCases {
            #expect(!liftType.icon.isEmpty, "icon should not be empty for \(liftType)")
        }
    }

    @Test("All icons start with 'figure.' prefix")
    func iconsUseFigurePrefix() {
        for liftType in LiftType.allCases {
            #expect(liftType.icon.hasPrefix("figure."), "icon for \(liftType) should start with 'figure.'")
        }
    }

    // MARK: - Color

    @Test("All lift types have a color")
    func allCasesHaveColor() {
        // Simply accessing the color for each case to verify it does not crash
        for liftType in LiftType.allCases {
            let _ = liftType.color
        }
    }

    @Test("Squat color is blue")
    func squatColorIsBlue() {
        #expect(LiftType.squat.color == .blue)
    }

    @Test("Bench press color is red")
    func benchPressColorIsRed() {
        #expect(LiftType.benchPress.color == .red)
    }

    @Test("Deadlift color is orange")
    func deadliftColorIsOrange() {
        #expect(LiftType.deadlift.color == .orange)
    }

    // MARK: - CaseIterable

    @Test("CaseIterable returns all 8 lift types")
    func caseIterableCount() {
        #expect(LiftType.allCases.count == 8)
    }

    @Test("CaseIterable contains expected cases")
    func caseIterableContainsExpectedCases() {
        let allCases = LiftType.allCases
        #expect(allCases.contains(.squat))
        #expect(allCases.contains(.benchPress))
        #expect(allCases.contains(.deadlift))
        #expect(allCases.contains(.overheadPress))
        #expect(allCases.contains(.clean))
        #expect(allCases.contains(.snatch))
        #expect(allCases.contains(.row))
        #expect(allCases.contains(.other))
    }

    // MARK: - Codable

    @Test("Codable round-trip for each case")
    func codableRoundTripForAllCases() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for liftType in LiftType.allCases {
            let data = try encoder.encode(liftType)
            let decoded = try decoder.decode(LiftType.self, from: data)
            #expect(decoded == liftType, "Codable round-trip failed for \(liftType)")
        }
    }

    @Test("Raw value encoding matches expected string")
    func rawValueEncoding() throws {
        let data = try JSONEncoder().encode(LiftType.benchPress)
        let jsonString = String(data: data, encoding: .utf8)

        #expect(jsonString?.contains("benchPress") == true)
    }

    @Test("Decoding from raw value string")
    func decodingFromRawValue() throws {
        let json = "\"overheadPress\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(LiftType.self, from: data)

        #expect(decoded == .overheadPress)
    }

    @Test("Decoding invalid raw value throws error")
    func decodingInvalidRawValueThrows() {
        let json = "\"invalidLift\""
        let data = json.data(using: .utf8)!

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(LiftType.self, from: data)
        }
    }

    // MARK: - Identifiable

    @Test("Identifiable id matches self")
    func identifiableIdMatchesSelf() {
        for liftType in LiftType.allCases {
            #expect(liftType.id == liftType)
        }
    }
}
