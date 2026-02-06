import SwiftUI

/// Camera recording screen with a live preview, lift type selector,
/// record button, and duration display.
struct RecordView: View {

    // MARK: - Properties

    @State private var viewModel = RecordViewModel()
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ZStack {
            // Camera preview fills the entire screen.
            CameraPreviewView(session: viewModel.captureSession)
                .ignoresSafeArea()

            VStack {
                topControls
                Spacer()
                bottomControls
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
        .navigationDestination(item: $viewModel.recordedVideoURL) { url in
            AnalysisProgressView(videoURL: url, liftType: viewModel.selectedLiftType)
        }
    }

    // MARK: - Top Controls

    private var topControls: some View {
        VStack(spacing: 12) {
            if viewModel.isRecording {
                durationDisplay
            }

            LiftTypePicker(selectedLiftType: $viewModel.selectedLiftType)
                .padding(.horizontal)
        }
        .padding(.top, 8)
    }

    // MARK: - Duration Display

    private var durationDisplay: some View {
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

    private var bottomControls: some View {
        VStack(spacing: 20) {
            recordButton
                .padding(.bottom, 40)
        }
    }

    // MARK: - Record Button

    private var recordButton: some View {
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
