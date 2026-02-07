import SwiftUI

/// Displays a list of recent analyses to select for comparison.
struct ComparisonPickerView: View {

    // MARK: - Properties

    let currentAnalysis: BarPathAnalysis
    @State private var recentAnalyses: [RecentAnalysis] = []
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        List {
            if recentAnalyses.isEmpty {
                ContentUnavailableView(
                    NSLocalizedString(
                        "comparison_no_analyses",
                        comment: "No analyses available for comparison"
                    ),
                    systemImage: "chart.bar.xaxis"
                )
            } else {
                ForEach(filteredAnalyses) { analysis in
                    Button {
                        navigateToComparison(with: analysis.id)
                    } label: {
                        analysisRow(analysis)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            loadRecentAnalyses()
        }
    }

    // MARK: - Filtered Analyses

    private var filteredAnalyses: [RecentAnalysis] {
        recentAnalyses.filter { $0.id != currentAnalysis.id }
    }

    // MARK: - Analysis Row

    private func analysisRow(_ analysis: RecentAnalysis) -> some View {
        HStack(spacing: 12) {
            Image(systemName: analysis.liftType.icon)
                .font(.title2)
                .foregroundStyle(analysis.liftType.color)
                .frame(width: 40, height: 40)
                .background(analysis.liftType.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(analysis.liftType.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(analysis.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func loadRecentAnalyses() {
        let persistence = PersistenceService()
        recentAnalyses = persistence.loadAnalyses()
    }

    private func navigateToComparison(with analysisID: UUID) {
        Task {
            let persistence = PersistenceService()
            if let selectedAnalysis = persistence.loadAnalysis(id: analysisID) {
                dismiss()

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    await presentComparison(
                        analysisA: currentAnalysis,
                        analysisB: selectedAnalysis,
                        from: rootViewController
                    )
                }
            }
        }
    }

    @MainActor
    private func presentComparison(
        analysisA: BarPathAnalysis,
        analysisB: BarPathAnalysis,
        from viewController: UIViewController
    ) async {
        let comparisonView = ComparisonView(analysisA: analysisA, analysisB: analysisB)
        let hostingController = UIHostingController(rootView: comparisonView)

        if let navigationController = findNavigationController(from: viewController) {
            navigationController.pushViewController(hostingController, animated: true)
        }
    }

    private func findNavigationController(from viewController: UIViewController) -> UINavigationController? {
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }

        if let presented = viewController.presentedViewController {
            return findNavigationController(from: presented)
        }

        for child in viewController.children {
            if let navigationController = findNavigationController(from: child) {
                return navigationController
            }
        }

        return nil
    }
}
