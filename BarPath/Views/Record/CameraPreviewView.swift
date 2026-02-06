import AVFoundation
import SwiftUI
import UIKit

/// A SwiftUI wrapper around AVCaptureVideoPreviewLayer that displays the live camera feed.
/// Uses UIViewRepresentable to bridge the AVFoundation preview layer into SwiftUI.
struct CameraPreviewView: UIViewRepresentable {

    // MARK: - Properties

    let session: AVCaptureSession

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }
}

// MARK: - Preview UIView

/// A UIView subclass that hosts an AVCaptureVideoPreviewLayer, ensuring the layer
/// resizes correctly with Auto Layout.
final class CameraPreviewUIView: UIView {

    // MARK: - Properties

    /// The preview layer displaying the camera feed.
    let previewLayer = AVCaptureVideoPreviewLayer()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(previewLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
