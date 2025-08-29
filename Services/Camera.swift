// Services/Camera.swift
import SwiftUI
import AVFoundation
import UIKit

// MARK: - Barcode Scanner (front-end only)
struct BarcodeScannerView: UIViewControllerRepresentable {
    final class ScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        var onCode: (String) -> Void = { _ in }
        let session = AVCaptureSession()
        override func viewDidLoad() {
            super.viewDidLoad()
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }
            session.beginConfiguration()
            if session.canAddInput(input) { session.addInput(input) }
            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) { session.addOutput(output) }
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.ean13, .ean8, .upce, .code128]
            session.commitConfiguration()
            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.bounds
            view.layer.addSublayer(preview)
            DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
        }
        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput objs: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            if let codeObj = objs.first as? AVMetadataMachineReadableCodeObject,
               let code = codeObj.stringValue { onCode(code) }
        }
    }
    var onCode: (String) -> Void
    func makeUIViewController(context: Context) -> ScannerVC { ScannerVC() }
    func updateUIViewController(_ vc: ScannerVC, context: Context) { vc.onCode = onCode }
}

// MARK: - Face Camera (front-end only)
final class CameraSessionController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var lastImage: UIImage? = nil
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    override init() {
        super.init()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        session.beginConfiguration()
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
    }
    func capture() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(), let img = UIImage(data: data) {
            DispatchQueue.main.async { self.lastImage = img }
        }
    }
}
struct FaceCameraView: UIViewControllerRepresentable {
    @ObservedObject var controller: CameraSessionController
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        let preview = AVCaptureVideoPreviewLayer(session: controller.session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = UIScreen.main.bounds
        vc.view.layer.addSublayer(preview)
        return vc
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
