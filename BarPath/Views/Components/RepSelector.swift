import SwiftUI

/// Horizontal scrolling rep selector with an "All" option and individual rep number pills.
/// The selected pill is highlighted with a blue background.
struct RepSelector: View {

    // MARK: - Properties

    /// The total number of reps available for selection.
    let repCount: Int

    /// The currently selected rep index, or nil when "All" is selected.
    @Binding var selectedRep: Int?

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                allPill
                repPills
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - All Pill

    private var allPill: some View {
        let isSelected = selectedRep == nil

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedRep = nil
            }
        } label: {
            Text(NSLocalizedString("rep_all", comment: "All reps selector"))
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            NSLocalizedString("rep_all_accessibility", comment: "Show all reps")
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Rep Pills

    private var repPills: some View {
        ForEach(0..<repCount, id: \.self) { index in
            let isSelected = selectedRep == index

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedRep = index
                }
            } label: {
                Text(
                    String(
                        format: NSLocalizedString(
                            "rep_number",
                            comment: "Individual rep label"
                        ),
                        index + 1
                    )
                )
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                String(
                    format: NSLocalizedString(
                        "rep_number_accessibility",
                        comment: "Rep number accessibility label"
                    ),
                    index + 1
                )
            )
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }
}
