import Foundation
import SwiftUI

/// Supported barbell lift types for bar path analysis.
enum LiftType: String, Codable, Sendable, CaseIterable, Identifiable {

    case squat
    case benchPress
    case deadlift
    case overheadPress
    case clean
    case snatch
    case row
    case other

    // MARK: - Identifiable

    var id: Self { self }

    // MARK: - Display Properties

    /// A localized, user-facing name for the lift type.
    var displayName: String {
        switch self {
        case .squat:
            return NSLocalizedString("lift_type_squat", comment: "Squat lift type")
        case .benchPress:
            return NSLocalizedString("lift_type_bench_press", comment: "Bench Press lift type")
        case .deadlift:
            return NSLocalizedString("lift_type_deadlift", comment: "Deadlift lift type")
        case .overheadPress:
            return NSLocalizedString("lift_type_overhead_press", comment: "Overhead Press lift type")
        case .clean:
            return NSLocalizedString("lift_type_clean", comment: "Clean lift type")
        case .snatch:
            return NSLocalizedString("lift_type_snatch", comment: "Snatch lift type")
        case .row:
            return NSLocalizedString("lift_type_row", comment: "Row lift type")
        case .other:
            return NSLocalizedString("lift_type_other", comment: "Other lift type")
        }
    }

    /// An SF Symbol icon representing the lift type.
    var icon: String {
        switch self {
        case .squat:
            return "figure.strengthtraining.traditional"
        case .benchPress:
            return "figure.strengthtraining.functional"
        case .deadlift:
            return "figure.highintensity.intervaltraining"
        case .overheadPress:
            return "figure.arms.open"
        case .clean:
            return "figure.cross.training"
        case .snatch:
            return "figure.mixed.cardio"
        case .row:
            return "figure.rowing"
        case .other:
            return "figure.walk"
        }
    }

    /// A color associated with the lift type for UI differentiation.
    var color: Color {
        switch self {
        case .squat:
            return .blue
        case .benchPress:
            return .red
        case .deadlift:
            return .orange
        case .overheadPress:
            return .purple
        case .clean:
            return .green
        case .snatch:
            return .yellow
        case .row:
            return .teal
        case .other:
            return .gray
        }
    }
}
