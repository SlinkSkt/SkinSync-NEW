import Foundation

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var logsByKey: [String: DayLog] = [:]
    @Published var routines: [Routine] = []
    @Published var productsByID: [UUID: Product] = [:]
    @Published var notif: NotificationPrefs

    private let store: DataStore
    private let scheduler: NotificationScheduler
    private let cal = Calendar(identifier: .gregorian)

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
            let logs  = (try? self.store.loadDayLogs()) ?? []
            await MainActor.run {
                self.productsByID = Dictionary(uniqueKeysWithValues: prods.map { ($0.id, $0) })
                self.routines = r
                self.logsByKey = Dictionary(uniqueKeysWithValues: logs.map { ($0.dateKey, $0) })
            }
        }
    }

    var dateKey: String { selectedDate.skinsyncDateKey }

    func toggle(_ slotID: UUID) {
        var log = logsByKey[dateKey] ?? DayLog(dateKey: dateKey, completedSlotIDs: [])
        if let idx = log.completedSlotIDs.firstIndex(of: slotID) {
            log.completedSlotIDs.remove(at: idx)
        } else {
            log.completedSlotIDs.append(slotID)
        }
        logsByKey[dateKey] = log
        persistLogs()
    }

    func isDone(_ slotID: UUID) -> Bool {
        logsByKey[dateKey]?.completedSlotIDs.contains(slotID) ?? false
    }

    private func persistLogs() {
        do { try store.save(dayLogs: Array(logsByKey.values)) } catch { }
    }

    func week(for base: Date) -> [Date] {
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: base)) ?? base
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    // Notifications
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
