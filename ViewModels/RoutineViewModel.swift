import Foundation

@MainActor
final class RoutineViewModel: ObservableObject {
    @Published var routines: [Routine] = []
    @Published var productsByID: [UUID: Product] = [:]
    @Published var notif: NotificationPrefs

    private let store: DataStore
    private let scheduler: NotificationScheduler

    init(store: DataStore, scheduler: NotificationScheduler) {
        self.store = store
        self.scheduler = scheduler
        self.notif = (try? store.loadNotificationPrefs())
        ?? NotificationPrefs(enableAM: false, amHour: 7, amMinute: 30,
                             enablePM: false, pmHour: 21, pmMinute: 0)
    }

    // MARK: - Load routines & products
    func load() {
        Task {
            let prods = (try? self.store.loadProducts()) ?? []
            let r     = (try? self.store.loadRoutines()) ?? []
            await MainActor.run {
                self.productsByID = Dictionary(uniqueKeysWithValues: prods.map { ($0.id, $0) })
                self.routines = r
                
            }
            print("Loaded routines: \(r.map { $0.title })")
        }
    }

    // MARK: - Set product for a routine slot
    func set(product: Product, for routineID: UUID, slotID: UUID) {
        guard let ridx = routines.firstIndex(where: { $0.id == routineID }),
              let sidx = routines[ridx].slots.firstIndex(where: { $0.id == slotID }) else { return }

        // Link product ID into the chosen slot
        routines[ridx].slots[sidx].productID = product.id

        // Ensure product is tracked in the dictionary
        productsByID[product.id] = product

        // Save changes
        save()
    }

    // MARK: - Save routines & products
    func save() {
        do {
            try store.save(routines: routines)
            try store.save(products: Array(productsByID.values))
        } catch {
            print("Failed to save routines/products: \(error)")
        }
    }

    // MARK: - Notifications
    func applyNotificationPrefs(_ prefs: NotificationPrefs) async {
        self.notif = prefs
        try? store.save(notificationPrefs: prefs)

        let granted = await scheduler.requestAuth()
        guard granted else { return }

        if prefs.enableAM {
            try? await scheduler.scheduleDaily(identifier: "skinsync.am",
                                               hour: prefs.amHour, minute: prefs.amMinute,
                                               body: "Time for your AM routine.")
        } else {
            await scheduler.cancel(identifier: "skinsync.am")
        }

        if prefs.enablePM {
            try? await scheduler.scheduleDaily(identifier: "skinsync.pm",
                                               hour: prefs.pmHour, minute: prefs.pmMinute,
                                               body: "Time for your PM routine.")
        } else {
            await scheduler.cancel(identifier: "skinsync.pm")
        }
    }
}
