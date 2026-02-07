import SwiftUI

/// Processing screen displayed during video analysis, showing a circular progress
/// indicator with percentage text and an animated status message.
struct AnalysisProgressView: View {

    // MARK: - Properties

    let videoURL: URL
    let liftType: LiftType

    @Environment(\.appSettings) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: AnalysisViewModel?

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                if let analysis = viewModel.analysis {
                    ResultView(analysis: analysis, hapticsEnabled: settings.hapticsEnabled)
                } else {
                    progressContent(viewModel: viewModel)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel?.cancelProcessing()
                    dismiss()
                } label: {
                    Text(NSLocalizedString("cancel", comment: "Cancel button"))
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                let vm = AnalysisViewModel(hapticsEnabled: settings.hapticsEnabled)
                viewModel = vm
                vm.processVideo(url: videoURL, liftType: liftType, calibration: settings.calibrationData)
            }
        }
        // TODO: Sprint 5 - Re-enable paywall
        // .sheet(isPresented: Binding(
        //     get: { viewModel?.showPaywall ?? false },
        //     set: { _ in }
        // )) {
        //     PaywallView()
        // }
    }

    // MARK: - Progress Content

    @ViewBuilder
    private func progressContent(viewModel: AnalysisViewModel) -> some View {
        VStack(spacing: 32) {
            Spacer()

            progressRing(viewModel: viewModel)

            statusText(viewModel: viewModel)

            if let error = viewModel.error {
                errorView(error, viewModel: viewModel)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Progress Ring

    @ViewBuilder
    private func progressRing(viewModel: AnalysisViewModel) -> some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(.quaternary, lineWidth: 8)
                .frame(width: 120, height: 120)

            // Progress ring
            Circle()
                .trim(from: 0, to: viewModel.progress)
                .stroke(
                    .blue,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: viewModel.progress)

            // Percentage text
            Text(percentageText(viewModel: viewModel))
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.easeInOut, value: percentageText(viewModel: viewModel))
        }
    }

    // MARK: - Status Text

    @ViewBuilder
    private func statusText(viewModel: AnalysisViewModel) -> some View {
        VStack(spacing: 8) {
            Text(viewModel.statusMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: viewModel.statusMessage)

            Text(liftType.displayName)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(_ message: String, viewModel: AnalysisViewModel) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.orange)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.processVideo(url: videoURL, liftType: liftType, calibration: settings.calibrationData)
            } label: {
                Text(NSLocalizedString("retry", comment: "Retry button"))
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Helpers

    private func percentageText(viewModel: AnalysisViewModel) -> String {
        "\(Int(viewModel.progress * 100))%"
    }
}
