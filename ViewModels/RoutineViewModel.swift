// https://www.swift.org/packages/database.html
import Foundation

/// Manages AM/PM routines, slot assignments, and reminder preferences.
/// Runs on the main actor so changes are safe for SwiftUI.
@MainActor
final class RoutineViewModel: ObservableObject {

    // MARK: - Published state
    @Published var routines: [Routine] = []
    @Published var productsByID: [UUID: Product] = [:]
    @Published var notif: NotificationPrefs

    // MARK: - Dependencies
    private let store: DataStore
    private let scheduler: NotificationScheduler   // no generics here

    // MARK: - Init
    init(store: DataStore, scheduler: NotificationScheduler) {
        self.store = store
        self.scheduler = scheduler
        self.notif = (try? store.loadNotificationPrefs())
        ?? NotificationPrefs(enableAM: false, amHour: 7, amMinute: 30,
                             enablePM: false, pmHour: 21, pmMinute: 0)
    }

    // MARK: - Loading
    /// Structured async load. Call as `Task { try? await vm.load() }` from views,
    /// or use the convenience `load()` wrapper below.
    func load() async throws {
        let prods = (try? store.loadProducts()) ?? []
        let r     = (try? store.loadRoutines()) ?? []

        productsByID = Dictionary(uniqueKeysWithValues: prods.map { ($0.id, $0) })
        routines = r

        // Create defaults if needed (AM/PM with sensible steps).
        if routines.isEmpty { ensureDefaultRoutinesIfNeeded() }
    }

    /// Convenience wrapper for `.onAppear` call sites.
    func load() { Task { try? await load() } }

    // MARK: - Defaults
    /// Create AM/PM with standard slots when no routines exist.
    func ensureDefaultRoutinesIfNeeded() {
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
        persistRoutines()
    }

    // MARK: - Slot assignment
    /// Link a product to a specific slot in a routine (e.g., assign Cleanser to AM/Cleanser).
    func set(product: Product, for routineID: UUID, slotID: UUID) {
        guard let rIndex = routines.firstIndex(where: { $0.id == routineID }),
              let sIndex = routines[rIndex].slots.firstIndex(where: { $0.id == slotID }) else {
            return
        }
        // Mutating nested state: notify manually for SwiftUI to refresh.
        routines[rIndex].slots[sIndex].productID = product.id
        productsByID[product.id] = product

        persistRoutines()
        persistProducts()
        objectWillChange.send()
    }

    /// Remove any product assigned to the given slot.
    func clearSlot(routineID: UUID, slotID: UUID) {
        guard let rIndex = routines.firstIndex(where: { $0.id == routineID }),
              let sIndex = routines[rIndex].slots.firstIndex(where: { $0.id == slotID }) else { return }
        routines[rIndex].slots[sIndex].productID = nil
        persistRoutines()
        objectWillChange.send()
    }

    // MARK: - Notifications
    /// Save prefs then schedule/cancel notifications accordingly.
    func applyNotificationPrefs(_ prefs: NotificationPrefs) async {
        self.notif = prefs
        try? store.save(notificationPrefs: prefs)

        let granted = await scheduler.requestAuth()
        guard granted else { return }

        if prefs.enableAM {
            try? await scheduler.scheduleDaily(
                identifier: "skinsync.am",
                hour: prefs.amHour, minute: prefs.amMinute,
                body: "Time for your AM routine."
            )
        } else {
            await scheduler.cancel(identifier: "skinsync.am")
        }

        if prefs.enablePM {
            try? await scheduler.scheduleDaily(
                identifier: "skinsync.pm",
                hour: prefs.pmHour, minute: prefs.pmMinute,
                body: "Time for your PM routine."
            )
        } else {
            await scheduler.cancel(identifier: "skinsync.pm")
        }
    }

    // MARK: - Persistence
    private func persistRoutines() {
        do { try store.save(routines: routines) } catch { /* optional: log */ }
    }

    private func persistProducts() {
        do { try store.save(products: Array(productsByID.values)) } catch { /* optional: log */ }
    }
}
