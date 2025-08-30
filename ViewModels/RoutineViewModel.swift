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

    func load() {
        Task {
            let prods = (try? self.store.loadProducts()) ?? []
            let r     = (try? self.store.loadRoutines()) ?? []
            await MainActor.run {
                self.productsByID = Dictionary(uniqueKeysWithValues: prods.map { ($0.id, $0) })
                self.routines = r
            }
            // ✅ If there are no routines yet, create sensible defaults
            await ensureDefaultRoutinesIfNeeded()
        }
    }

    /// Create AM/PM with sensible slots if missing
    func ensureDefaultRoutinesIfNeeded() async {
        guard routines.isEmpty else { return }
        let am = Routine(
            title: "AM",
            slots: [
                RoutineSlot(step: "Cleanser"),
                RoutineSlot(step: "Treatment"),
                RoutineSlot(step: "Moisturiser"),
                RoutineSlot(step: "Sunscreen")
            ]
        )
        let pm = Routine(
            title: "PM",
            slots: [
                RoutineSlot(step: "Cleanser"),
                RoutineSlot(step: "Treatment"),
                RoutineSlot(step: "Moisturiser")
            ]
        )
        routines = [am, pm]
        save()
    }

    func set(product: Product, for routineID: UUID, slotID: UUID) {
        guard let ridx = routines.firstIndex(where: { $0.id == routineID }),
              let sidx = routines[ridx].slots.firstIndex(where: { $0.id == slotID }) else { return }

        routines[ridx].slots[sidx].productID = product.id
        productsByID[product.id] = product

        // Save both routines and products (products now include persisted IDs)
        save()
        try? store.save(products: Array(productsByID.values))

        objectWillChange.send()
    }

    func save() {
        do { try store.save(routines: routines) } catch { }
    }

    // MARK: Notifications
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
