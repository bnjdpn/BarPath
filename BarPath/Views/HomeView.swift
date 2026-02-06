import PhotosUI
import SwiftUI

/// Main home screen displaying record and import actions, along with a list of recent analyses.
struct HomeView: View {

    // MARK: - Properties

    @State private var viewModel = HomeViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var importedVideoURL: URL?
    @State private var selectedLiftType: LiftType = .squat

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                actionSection
                recentSection
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("home_title", comment: "Home screen title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: NavigationDestination.settings) {
                    Image(systemName: "gearshape")
                        .accessibilityLabel(
                            NSLocalizedString(
                                "settings_button",
                                comment: "Settings toolbar button"
                            )
                        )
                }
            }
        }
        .navigationDestination(item: $importedVideoURL) { url in
            AnalysisProgressView(videoURL: url, liftType: selectedLiftType)
        }
        .onAppear {
            viewModel.loadRecent()
        }
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: 16) {
            NavigationLink(value: NavigationDestination.record) {
                Label {
                    Text(NSLocalizedString("home_record_button", comment: "Record button title"))
                        .fontWeight(.semibold)
                } icon: {
                    Image(systemName: "camera.fill")
                }
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .videos
            ) {
                Label {
                    Text(
                        NSLocalizedString(
                            "home_import_button",
                            comment: "Import video button title"
                        )
                    )
                    .fontWeight(.medium)
                } icon: {
                    Image(systemName: "square.and.arrow.down")
                }
                .font(.body)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.quaternary)
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    await handleImportedVideo(item: newItem)
                }
            }
        }
    }

    // MARK: - Recent Analyses Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.recentAnalyses.isEmpty {
                Text(
                    NSLocalizedString(
                        "home_recent_section",
                        comment: "Recent analyses section header"
                    )
                )
                .font(.headline)
                .foregroundStyle(.secondary)

                LazyVStack(spacing: 8) {
                    ForEach(viewModel.recentAnalyses) { analysis in
                        NavigationLink(
                            value: NavigationDestination.historyDetail(analysisID: analysis.id)
                        ) {
                            recentAnalysisRow(analysis)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteAnalysis(id: analysis.id)
                            } label: {
                                Label(
                                    NSLocalizedString(
                                        "delete",
                                        comment: "Delete action"
                                    ),
                                    systemImage: "trash"
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Analysis Row

    private func recentAnalysisRow(_ analysis: RecentAnalysis) -> some View {
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

            VStack(alignment: .trailing, spacing: 2) {
                Text(
                    String(
                        format: NSLocalizedString(
                            "home_rep_count",
                            comment: "Rep count label"
                        ),
                        analysis.repCount
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 2) {
                    Text(String(format: "%.2f", analysis.peakVelocity))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(
                        NSLocalizedString(
                            "unit_velocity",
                            comment: "Velocity unit"
                        )
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Video Import

    @MainActor
    private func handleImportedVideo(item: PhotosPickerItem?) async {
        guard let item else { return }

        // Load the video data from the Photos picker.
        guard let videoData = try? await item.loadTransferable(type: Data.self) else { return }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        do {
            try videoData.write(to: tempURL)
            importedVideoURL = tempURL
        } catch {
            // Video import failed; handled silently.
        }
    }
}
