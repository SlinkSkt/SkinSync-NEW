import Foundation
import SwiftUI

/// Manages notification preferences for AM/PM routine reminders
@MainActor
final class NotificationViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var notif: NotificationPrefs
    
    // MARK: - Dependencies
    private let store: DataStore
    private let scheduler: NotificationScheduler
    
    // MARK: - Init
    init(store: DataStore, scheduler: NotificationScheduler) {
        self.store = store
        self.scheduler = scheduler
        self.notif = (try? store.loadNotificationPrefs()) 
            ?? NotificationPrefs(
                enableAM: false, 
                amHour: 7, 
                amMinute: 30,
                enablePM: false, 
                pmHour: 21, 
                pmMinute: 0
            )
        print("🔔 NotificationViewModel: Initialized with AM: \(notif.enableAM), PM: \(notif.enablePM)")
    }
    
    // MARK: - Notification Management
    func applyNotificationPrefs(_ prefs: NotificationPrefs) async {
        do {
            try store.save(notificationPrefs: prefs)
            
            // Cancel existing notifications
            await scheduler.cancel(identifier: "morning_routine")
            await scheduler.cancel(identifier: "evening_routine")
            
            // Schedule new notifications if enabled
            if prefs.enableAM {
                try await scheduler.scheduleDaily(
                    identifier: "morning_routine",
                    hour: prefs.amHour,
                    minute: prefs.amMinute,
                    body: "Time for your morning skincare routine! 🌅"
                )
            }
            
            if prefs.enablePM {
                try await scheduler.scheduleDaily(
                    identifier: "evening_routine",
                    hour: prefs.pmHour,
                    minute: prefs.pmMinute,
                    body: "Time for your evening skincare routine! 🌙"
                )
            }
            
            print("🔔 NotificationViewModel: Applied notification preferences")
        } catch {
            print("🔔 NotificationViewModel: Failed to apply notification preferences: \(error)")
        }
    }
    
    // MARK: - Permission Management
    func requestNotificationPermission() async -> Bool {
        let granted = await scheduler.requestAuth()
        print("🔔 NotificationViewModel: Notification permission \(granted ? "granted" : "denied")")
        return granted
    }
    
    // MARK: - Convenience Methods
    func updateAMReminder(enabled: Bool, hour: Int, minute: Int) {
        notif.enableAM = enabled
        notif.amHour = hour
        notif.amMinute = minute
        
        Task {
            await applyNotificationPrefs(notif)
        }
    }
    
    func updatePMReminder(enabled: Bool, hour: Int, minute: Int) {
        notif.enablePM = enabled
        notif.pmHour = hour
        notif.pmMinute = minute
        
        Task {
            await applyNotificationPrefs(notif)
        }
    }
}
