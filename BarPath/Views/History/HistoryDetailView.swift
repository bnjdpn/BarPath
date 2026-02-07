import SwiftUI

/// Detail view for a previously saved analysis, loaded from persistence by its identifier.
/// Presents the same result interface as ResultView once the data is loaded.
struct HistoryDetailView: View {

    // MARK: - Properties

    let analysisID: UUID

    @State private var analysis: BarPathAnalysis?
    @State private var loadError = false
    @Environment(\.appSettings) private var settings

    private let persistence: DataStoring

    // MARK: - Initialization

    init(analysisID: UUID, persistence: DataStoring = PersistenceService()) {
        self.analysisID = analysisID
        self.persistence = persistence
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let analysis {
                ResultView(analysis: analysis, hapticsEnabled: settings.hapticsEnabled)
            } else if loadError {
                errorContent
            } else {
                ProgressView()
            }
        }
        .onAppear {
            loadAnalysis()
        }
    }

    // MARK: - Error Content

    private var errorContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text(
                NSLocalizedString(
                    "history_load_error",
                    comment: "Error message when analysis cannot be loaded"
                )
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Loading

    private func loadAnalysis() {
        if let loaded = persistence.loadAnalysis(id: analysisID) {
            analysis = loaded
        } else {
            loadError = true
        }
    }
}
