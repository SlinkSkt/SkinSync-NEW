import Foundation
import UIKit

@MainActor
final class ScanViewModel: ObservableObject {
    @Published var scannedProduct: Product?
    @Published var lastFaceScan: FaceScanResult?
    @Published var analyzingFace: Bool = false

    private let store: DataStore
    init(productAPI: Any, faceAPI: Any, store: DataStore) { self.store = store }

    // BARCODE → find in local products list
    func onBarcode(_ code: String) {
        Task {
            let products = (try? self.store.loadProducts()) ?? []
            let found = products.first { $0.barcode == code }
            await MainActor.run { self.scannedProduct = found }
        }
    }

    // FACE → mock result + persist
    func analyzeFace(image: UIImage) {
        analyzingFace = true
        Task {
            let possible: [Concern] = [.acne, .redness, .dryness, .oiliness, .sensitivity]
            let picked = Array(possible.shuffled().prefix(2)).sorted { $0.rawValue < $1.rawValue }

            let result = FaceScanResult(
                id: UUID(),
                timestamp: Date(),         // correct parameter order
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
