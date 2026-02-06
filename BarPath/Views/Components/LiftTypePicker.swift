import SwiftUI

/// Horizontal scrolling lift type selector displaying all lift types as tappable pills.
/// The selected lift type is highlighted with its associated color.
struct LiftTypePicker: View {

    // MARK: - Properties

    @Binding var selectedLiftType: LiftType

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LiftType.allCases) { liftType in
                    liftTypeChip(liftType)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Chip

    private func liftTypeChip(_ liftType: LiftType) -> some View {
        let isSelected = selectedLiftType == liftType

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedLiftType = liftType
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: liftType.icon)
                    .font(.caption2)

                Text(liftType.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? AnyShapeStyle(liftType.color)
                    : AnyShapeStyle(.quaternary)
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(liftType.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
