import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleExpirationNotifications(for item: EmergencyItem) async {
        guard let expirationDate = item.expirationDate else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers(for: item))

        let reminders: [(days: Int, label: String)] = [
            (180, "6 μήνες"),
            (90, "3 μήνες"),
            (30, "30 ημέρες"),
            (7, "7 ημέρες")
        ]

        for reminder in reminders {
            guard let reminderDate = Calendar.current.date(byAdding: .day, value: -reminder.days, to: expirationDate),
                  reminderDate > .now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "ReadyKit • Λήξη προϊόντος"
            content.body = "Το \(item.name) λήγει σε \(reminder.label). Έλεγξέ το και προγραμμάτισε αντικατάσταση."
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "expiration-\(item.id.uuidString)-\(reminder.days)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func removeNotifications(for item: EmergencyItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers(for: item))
    }

    private func identifiers(for item: EmergencyItem) -> [String] {
        [180, 90, 30, 7].map { "expiration-\(item.id.uuidString)-\($0)" }
    }
}
