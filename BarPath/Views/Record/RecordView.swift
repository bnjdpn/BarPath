import SwiftUI

/// Camera recording screen with a live preview, lift type selector,
/// record button, and duration display.
struct RecordView: View {

    // MARK: - Properties

    @Environment(\.appSettings) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: RecordViewModel?

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel: viewModel)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = RecordViewModel(
                    preferredLiftType: settings.preferredLiftType,
                    recordingFPS: settings.recordingFPS,
                    hapticsEnabled: settings.hapticsEnabled
                )
            }
        }
    }

    @ViewBuilder
    private func content(viewModel: RecordViewModel) -> some View {
        ZStack {
            // Camera preview fills the entire screen.
            CameraPreviewView(session: viewModel.captureSession)
                .ignoresSafeArea()

            VStack {
                topControls(viewModel: viewModel)
                Spacer()
                bottomControls(viewModel: viewModel)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.tearDown()
                    dismiss()
                } label: {
                    Text(NSLocalizedString("cancel", comment: "Cancel button"))
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear {
            viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.tearDown()
        }
        .navigationDestination(item: Binding(
            get: { viewModel.recordedVideoURL },
            set: { _ in }
        )) { url in
            AnalysisProgressView(videoURL: url, liftType: viewModel.selectedLiftType)
        }
    }

    // MARK: - Top Controls

    @ViewBuilder
    private func topControls(viewModel: RecordViewModel) -> some View {
        VStack(spacing: 12) {
            if viewModel.isRecording {
                durationDisplay(viewModel: viewModel)
            }

            LiftTypePicker(selectedLiftType: Binding(
                get: { viewModel.selectedLiftType },
                set: { _ in }
            ))
            .padding(.horizontal)
        }
        .padding(.top, 8)
    }

    // MARK: - Duration Display

    @ViewBuilder
    private func durationDisplay(viewModel: RecordViewModel) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)

            Text(viewModel.formattedDuration)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.black.opacity(0.6))
        .clipShape(Capsule())
    }

    // MARK: - Bottom Controls

    @ViewBuilder
    private func bottomControls(viewModel: RecordViewModel) -> some View {
        VStack(spacing: 20) {
            recordButton(viewModel: viewModel)
                .padding(.bottom, 40)
        }
    }

    // MARK: - Record Button

    @ViewBuilder
    private func recordButton(viewModel: RecordViewModel) -> some View {
        Button {
            if viewModel.isRecording {
                viewModel.stopRecording()
            } else {
                viewModel.startRecording()
            }
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 72, height: 72)

                // Inner shape: circle when idle, rounded square when recording
                if viewModel.isRecording {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.red)
                        .frame(width: 30, height: 30)
                } else {
                    Circle()
                        .fill(.red)
                        .frame(width: 60, height: 60)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
        }
        .accessibilityLabel(
            viewModel.isRecording
                ? NSLocalizedString("record_stop", comment: "Stop recording")
                : NSLocalizedString("record_start", comment: "Start recording")
        )
    }
}

// MARK: - URL Extension for NavigationDestination

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
