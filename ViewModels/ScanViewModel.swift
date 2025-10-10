import Foundation
import UIKit
import AVFoundation
import VisionKit

@MainActor
final class ScanViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var scannedProduct: Product?
    @Published var lastFaceScan: FaceScanResult?
    @Published var analyzingFace: Bool = false
    @Published var scannedBarcode: String?
    @Published var isScanning: Bool = false
    @Published var isTorchOn: Bool = false
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var isDataScannerAvailable: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var detectedBarcode: String?
    @Published var showProductNotFound: Bool = false
    
    // MARK: - Private Properties
    private let store: DataStore
    private let productRepository: ProductRepository?
    private var lastDetectedCode: String?
    private var lastDetectionTime: Date?
    private let detectionThrottleInterval: TimeInterval = 2.0
    
    // MARK: - Initialization
    init(productRepository: ProductRepository?, faceAPI: Any, store: DataStore) { 
        self.store = store
        self.productRepository = productRepository
        checkDataScannerAvailability()
        checkCameraPermission()
    }
    
    // MARK: - DataScanner Availability
    func checkDataScannerAvailability() {
        isDataScannerAvailable = DataScannerViewController.isSupported && DataScannerViewController.isAvailable
        print("🔍 ScanViewModel: DataScanner available: \(isDataScannerAvailable)")
    }
    
    // MARK: - Camera Permissions
    func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        print("🔍 ScanViewModel: Camera permission status: \(cameraPermissionStatus.rawValue)")
    }
    
    func requestCameraPermission() async {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        }
        print("🔍 ScanViewModel: Camera permission granted: \(status)")
    }
    
    // MARK: - Barcode Detection
    func onBarcodeDetected(_ code: String) {
        print("🔍 ScanViewModel: onBarcodeDetected called with: \(code)")
        
        // Throttle duplicate detections
        let now = Date()
        if let lastCode = lastDetectedCode,
           let lastTime = lastDetectionTime,
           lastCode == code,
           now.timeIntervalSince(lastTime) < detectionThrottleInterval {
            print("🔍 ScanViewModel: Throttling duplicate detection: \(code)")
            return
        }
        
        lastDetectedCode = code
        lastDetectionTime = now
        detectedBarcode = code
        
        print("🔍 ScanViewModel: Processing barcode: \(code)")
        
        // Stop scanning to avoid multiple triggers
        isScanning = false
        print("🔍 ScanViewModel: Stopped scanning")
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        print("🔍 ScanViewModel: Haptic feedback triggered")
        
        // Fetch product
        print("🔍 ScanViewModel: Starting product fetch for barcode: \(code)")
        fetchProductByBarcode(code)
    }
    
    private func fetchProductByBarcode(_ barcode: String) {
        print("🔍 ScanViewModel: fetchProductByBarcode called with: \(barcode)")
        isLoading = true
        errorMessage = nil
        showProductNotFound = false
        
        Task {
            do {
                // First try to fetch from API
                if let repository = productRepository {
                    print("🔍 ScanViewModel: Attempting API fetch for barcode: \(barcode)")
                    if let product = try await repository.fetchByBarcode(barcode) {
                        print("🔍 ScanViewModel: API fetch successful, product: \(product.name)")
                        await MainActor.run {
                            self.scannedProduct = product
                            self.scannedBarcode = barcode
                            self.isLoading = false
                        }
                        return
                    } else {
                        print("🔍 ScanViewModel: API fetch returned nil for barcode: \(barcode)")
                    }
                } else {
                    print("🔍 ScanViewModel: No productRepository available")
                }
                
                // If API fails, try cached products
                print("🔍 ScanViewModel: Trying cached products for barcode: \(barcode)")
                let cachedProducts = (try? store.loadProducts()) ?? []
                print("🔍 ScanViewModel: Found \(cachedProducts.count) cached products")
                if let cachedProduct = cachedProducts.first(where: { $0.barcode == barcode }) {
                    print("🔍 ScanViewModel: Found cached product: \(cachedProduct.name)")
                    await MainActor.run {
                        self.scannedProduct = cachedProduct
                        self.scannedBarcode = barcode
                        self.isLoading = false
                    }
                    return
                } else {
                    print("🔍 ScanViewModel: No cached product found for barcode: \(barcode)")
                }
                
                // Product not found
                print("🔍 ScanViewModel: Product not found for barcode: \(barcode)")
                await MainActor.run {
                    self.showProductNotFound = true
                    self.isLoading = false
                }
                
            } catch {
                print("🔍 ScanViewModel: Error fetching product: \(error)")
                
                // Check if it's a network error vs product not found
                if let apiError = error as? APIError {
                    switch apiError {
                    case .invalidResponse:
                        // This could be a 404 (product not found) or other HTTP error
                        print("🔍 ScanViewModel: API returned invalid response - likely product not found")
                        await MainActor.run {
                            self.showProductNotFound = true
                            self.isLoading = false
                        }
                    default:
                        await MainActor.run {
                            self.errorMessage = "Network error: \(error.localizedDescription)"
                            self.isLoading = false
                        }
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Failed to fetch product: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    // MARK: - Scanner Controls
    func startScanning() {
        guard cameraPermissionStatus == .authorized else {
            print("🔍 ScanViewModel: Camera permission not granted")
            return
        }
        
        print("🔍 ScanViewModel: Starting scan - current isScanning: \(isScanning)")
        isScanning = true
        errorMessage = nil
        showProductNotFound = false
        scannedProduct = nil
        detectedBarcode = nil
        print("🔍 ScanViewModel: Scan started - isScanning: \(isScanning)")
    }
    
    func stopScanning() {
        isScanning = false
        print("🔍 ScanViewModel: Stopping scan")
    }
    
    func toggleTorch() {
        isTorchOn.toggle()
        print("🔍 ScanViewModel: Torch toggled: \(isTorchOn)")
    }
    
    func reset() {
        print("🔍 ScanViewModel: Resetting scanner state")
        isScanning = false
        isLoading = false
        errorMessage = nil
        showProductNotFound = false
        scannedProduct = nil
        scannedBarcode = nil
        detectedBarcode = nil
        lastDetectedCode = nil
        lastDetectionTime = nil
        print("🔍 ScanViewModel: Reset complete - isScanning: \(isScanning)")
    }
    
    // MARK: - Face Analysis (Legacy)
    func analyzeFace(image: UIImage) {
        analyzingFace = true
        Task {
            let possible: [Concern] = [.acne, .redness, .dryness, .oiliness, .sensitivity]
            let picked = Array(possible.shuffled().prefix(2)).sorted { $0.rawValue < $1.rawValue }

            let result = FaceScanResult(
                id: UUID(),
                timestamp: Date(),
                concerns: picked,
                notes: nil
            )

            do {
                var scans = try store.loadScans()
                scans.append(result)
                try store.save(scans: scans)
            } catch { }

            await MainActor.run {
                self.lastFaceScan = result
                self.analyzingFace = false
            }
        }
    }
}
