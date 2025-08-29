// Services/Notifications.swift
import Foundation
import UserNotifications

protocol NotificationScheduler {
    func requestAuth() async -> Bool
    func scheduleDaily(identifier: String, hour: Int, minute: Int, body: String) async throws
    func cancel(identifier: String) async
}

final class LocalNotificationScheduler: NotificationScheduler {
    func requestAuth() async -> Bool {
        await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    cont.resume(returning: granted)
                }
        }
    }

    func scheduleDaily(identifier: String, hour: Int, minute: Int, body: String) async throws {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "SkinSync Reminder"
        content.body = body
        content.sound = .default

        var dc = DateComponents()
        dc.hour = hour
        dc.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)

        let req = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            center.add(req) { error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: ())
                }
            }
        }
    }

    func cancel(identifier: String) async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
