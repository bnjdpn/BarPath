import SwiftUI

/// Processing screen displayed during video analysis, showing a circular progress
/// indicator with percentage text and an animated status message.
struct AnalysisProgressView: View {

    // MARK: - Properties

    let videoURL: URL
    let liftType: LiftType

    @State private var viewModel = AnalysisViewModel()
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        Group {
            if let analysis = viewModel.analysis {
                ResultView(analysis: analysis)
            } else {
                progressContent
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.cancelProcessing()
                    dismiss()
                } label: {
                    Text(NSLocalizedString("cancel", comment: "Cancel button"))
                }
            }
        }
        .onAppear {
            viewModel.processVideo(url: videoURL, liftType: liftType)
        }
    }

    // MARK: - Progress Content

    private var progressContent: some View {
        VStack(spacing: 32) {
            Spacer()

            progressRing

            statusText

            if let error = viewModel.error {
                errorView(error)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
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
            Text(percentageText)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.easeInOut, value: percentageText)
        }
    }

    // MARK: - Status Text

    private var statusText: some View {
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

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.orange)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.processVideo(url: videoURL, liftType: liftType)
            } label: {
                Text(NSLocalizedString("retry", comment: "Retry button"))
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Helpers

    private var percentageText: String {
        "\(Int(viewModel.progress * 100))%"
    }
}
