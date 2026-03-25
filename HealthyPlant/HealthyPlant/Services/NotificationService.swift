import Foundation
import UserNotifications

final class NotificationService {
    private let center = UNUserNotificationCenter.current()

    // MARK: - Request Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("[NotificationService] Permission error: \(error)")
            return false
        }
    }

    // MARK: - Schedule Local Notification

    func scheduleLocalNotification(for event: CalendarEvent) {
        let content = UNMutableNotificationContent()
        content.title = event.eventType.label
        content.body = "\(event.plantName): \(event.description)"
        content.sound = .default

        // Schedule for 8 AM on the event date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let eventDate = formatter.date(from: event.date) ?? Date()
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: eventDate
        )
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "event-\(event.id)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("[NotificationService] Failed to schedule: \(error)")
            }
        }
    }

    // MARK: - Remove Notification

    func removeNotification(eventId: String) {
        center.removePendingNotificationRequests(
            withIdentifiers: ["event-\(eventId)"]
        )
    }

    // MARK: - Remove All

    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
}
