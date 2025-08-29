import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var latestScan: FaceScanResult?
    @Published var recommendations: [Product] = []

    private let store: DataStore
    init(store: DataStore) { self.store = store }

    func load() {
        Task {
            // Sync loads on a background task context
            let allScans  = (try? self.store.loadScans()) ?? []
            let allProds  = (try? self.store.loadProducts()) ?? []

            let sorted = allScans.sorted { $0.timestamp > $1.timestamp }
            let latest = sorted.first

            await MainActor.run {
                self.latestScan = latest
                if let concerns = latest?.concerns {
                    let detected = Set(concerns)
                    self.recommendations = allProds.filter {
                        !Set($0.concerns).isDisjoint(with: detected)
                    }.prefix(5).map { $0 }
                } else {
                    self.recommendations = Array(allProds.prefix(5))
                }
            }
        }
    }
}
