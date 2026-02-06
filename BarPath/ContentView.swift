import SwiftUI

/// Root view providing the NavigationStack and managing app-level navigation.
struct ContentView: View {

    // MARK: - Body

    var body: some View {
        NavigationStack {
            HomeView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .record:
                        RecordView()

                    case .processing(let videoURL, let liftType):
                        AnalysisProgressView(videoURL: videoURL, liftType: liftType)

                    case .result(let analysis):
                        ResultView(analysis: analysis)

                    case .historyDetail(let analysisID):
                        HistoryDetailView(analysisID: analysisID)

                    case .settings:
                        SettingsView()
                    }
                }
        }
    }
}

// MARK: - Navigation Destination

/// Type-safe navigation destinations used throughout the app.
enum NavigationDestination: Hashable {
    case record
    case processing(videoURL: URL, liftType: LiftType)
    case result(analysis: BarPathAnalysis)
    case historyDetail(analysisID: UUID)
    case settings
}

// MARK: - BarPathAnalysis Hashable Conformance

extension BarPathAnalysis: Hashable {
    static func == (lhs: BarPathAnalysis, rhs: BarPathAnalysis) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
