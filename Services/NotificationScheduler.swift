// Services/NotificationScheduler.swift
// https://developer.apple.com/documentation/usernotifications
import Foundation
import UserNotifications

/// Abstraction for scheduling and managing local notifications.
/// Allows to swap in different implementations if needed (e.g. for testing).
protocol NotificationScheduler {
    /// Request notification authorization from the user.
    func requestAuth() async -> Bool
    
    /// Schedule a repeating daily notification at the given time.
    func scheduleDaily(identifier: String, hour: Int, minute: Int, body: String) async throws
    
    /// Cancel any scheduled notification with the given identifier.
    func cancel(identifier: String) async
}

/// Default implementation that uses UNUserNotificationCenter.
final class LocalNotificationScheduler: NotificationScheduler {
    
    /// Request permission to show alerts, sounds, and badges.
    func requestAuth() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    continuation.resume(returning: granted)
                }
        }
    }

    /// Schedule a repeating daily notification at a specific time.
    func scheduleDaily(identifier: String, hour: Int, minute: Int, body: String) async throws {
        let center = UNUserNotificationCenter.current()
        
        // Build notification content
        let content = UNMutableNotificationContent()
        content.title = "SkinSync Reminder"
        content.body = body
        content.sound = .default
        
        // Fire at a specific hour/minute every day
        var dc = DateComponents()
        dc.hour = hour
        dc.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        
        // Add request to notification center
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Cancel a previously scheduled notification.
    func cancel(identifier: String) async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
