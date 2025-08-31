// Services/Camera.swift
// UIKit bridges for camera-based features used by SwiftUI.
// - BarcodeScannerView: front-end barcode reader (EAN/UPC/Code128) that emits scanned codes.
// - FaceCameraView: front-facing live preview with capture support (front-end only).
// Back-end/API calls are handled elsewhere (e.g., a ViewModel).
// !!!!!!!!!! ---- STILL UNDER DEVELOPMENT, PLEASE EXCLUDE THIS FROM THE ASSESSMENT 1  --- !!!!!!!!!!
// !!!!!!!!!! ---- STILL UNDER DEVELOPMENT, PLEASE EXCLUDE THIS FROM THE ASSESSMENT 1  --- !!!!!!!!!!
// !!!!!!!!!! ---- STILL UNDER DEVELOPMENT, PLEASE EXCLUDE THIS FROM THE ASSESSMENT 1  --- !!!!!!!!!!
// !!!!!!!!!! ---- STILL UNDER DEVELOPMENT, PLEASE EXCLUDE THIS FROM THE ASSESSMENT 1  --- !!!!!!!!!!
import SwiftUI
import AVFoundation
import UIKit

// MARK: - Utilities

/// Simple helper for camera permission flow.
private enum CameraPermission {
    static func ensureAuthorized(for mediaType: AVMediaType = .video,
                                 completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: mediaType) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            completion(false)
        }
    }
}

// MARK: - Barcode Scanner (front-end only)

/// A SwiftUI wrapper that presents a live camera preview and scans for common barcodes.
/// Emits the first detected value via the `onCode` closure.
struct BarcodeScannerView: UIViewControllerRepresentable {
    final class ScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        var onCode: (String) -> Void = { _ in }
        private let session = AVCaptureSession()
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private let metadataOutput = AVCaptureMetadataOutput()

        private let supportedTypes: [AVMetadataObject.ObjectType] = [
            .ean13, .ean8, .upce, .code128
        ]

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            configureSessionIfAuthorized()
        }

        private func configureSessionIfAuthorized() {
            CameraPermission.ensureAuthorized { [weak self] granted in
                guard let self else { return }
                guard granted else {
                    self.showPermissionLabel()
                    return
                }
                self.configureSession()
                self.configurePreview()
                DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
            }
        }

        private func configureSession() {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }

            session.beginConfiguration()
            if session.canAddInput(input) { session.addInput(input) }
            if session.canAddOutput(metadataOutput) { session.addOutput(metadataOutput) }
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = supportedTypes
            session.commitConfiguration()
        }

        private func configurePreview() {
            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.bounds
            view.layer.addSublayer(preview)
            self.previewLayer = preview
        }

        private func showPermissionLabel() {
            let label = UILabel()
            label.text = "Camera access is required to scan barcodes. Enable it in Settings."
            label.textColor = .white
            label.numberOfLines = 0
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            previewLayer?.frame = view.bounds
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if session.isRunning { session.stopRunning() }
        }

        deinit {
            if session.isRunning { session.stopRunning() }
        }

        // MARK: AVCaptureMetadataOutputObjectsDelegate
        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput objs: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            // Emit first code detected
            guard let codeObj = objs.first as? AVMetadataMachineReadableCodeObject,
                  let code = codeObj.stringValue else { return }
            onCode(code)
        }
    }

    var onCode: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerVC { ScannerVC() }
    func updateUIViewController(_ vc: ScannerVC, context: Context) { vc.onCode = onCode }
}

// MARK: - Face Camera (front-end only)

/// Observable controller that manages a capture session and last captured image.
final class CameraSessionController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var lastImage: UIImage? = nil
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()

    override init() {
        super.init()
        CameraPermission.ensureAuthorized { [weak self] granted in
            guard let self else { return }
            guard granted else { return }
            self.configureSession()
            DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
        }
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        session.beginConfiguration()
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
    }

    func capture() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    // MARK: AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(), let img = UIImage(data: data) {
            DispatchQueue.main.async { self.lastImage = img }
        }
    }
}

/// A SwiftUI wrapper that shows a live preview for the given `CameraSessionController`.
struct FaceCameraView: UIViewControllerRepresentable {
    @ObservedObject var controller: CameraSessionController

    final class PreviewVC: UIViewController {
        let session: AVCaptureSession
        private var previewLayer: AVCaptureVideoPreviewLayer?
        init(session: AVCaptureSession) {
            self.session = session
            super.init(nibName: nil, bundle: nil)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.bounds
            view.layer.addSublayer(preview)
            self.previewLayer = preview
        }
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            previewLayer?.frame = view.bounds
        }
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if session.isRunning { session.stopRunning() }
        }
        deinit {
            if session.isRunning { session.stopRunning() }
        }
    }

    func makeUIViewController(context: Context) -> PreviewVC {
        PreviewVC(session: controller.session)
    }

    func updateUIViewController(_ uiViewController: PreviewVC, context: Context) {
        // Nothing to update—session is managed by the controller
    }
}
