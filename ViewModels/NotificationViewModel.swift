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
    
    // MARK: - Notification Messages
    private let morningMessages = [
        "Rise and shine! ☀️ Time for your morning skincare routine",
        "Good morning! 🌅 Your skin is waiting for some love",
        "Start your day fresh! ✨ Morning skincare time",
        "Wake up and glow! 🌟 Your morning routine awaits",
        "Morning beauty ritual time! 💆‍♀️ Let's get glowing"
    ]
    
    private let eveningMessages = [
        "Unwind with your evening routine 🌙 Your skin deserves it",
        "Good night! 🌟 Don't forget your evening skincare",
        "Bedtime beauty ritual! 💫 Take care of your skin tonight",
        "Evening glow time! ✨ Your skincare routine is calling",
        "Sweet dreams start here 🌛 Evening skincare awaits"
    ]
    
    private func getRandomMessage(isMorning: Bool) -> String {
        let messages = isMorning ? morningMessages : eveningMessages
        return messages.randomElement() ?? (isMorning 
            ? "Time for your morning skincare routine! ☀️"
            : "Time for your evening skincare routine! 🌙")
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
                    body: getRandomMessage(isMorning: true)
                )
                print("🔔 NotificationViewModel: Scheduled morning reminder at \(prefs.amHour):\(String(format: "%02d", prefs.amMinute))")
            }
            
            if prefs.enablePM {
                try await scheduler.scheduleDaily(
                    identifier: "evening_routine",
                    hour: prefs.pmHour,
                    minute: prefs.pmMinute,
                    body: getRandomMessage(isMorning: false)
                )
                print("🔔 NotificationViewModel: Scheduled evening reminder at \(prefs.pmHour):\(String(format: "%02d", prefs.pmMinute))")
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
