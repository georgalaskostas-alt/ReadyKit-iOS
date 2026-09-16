import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() async -> Bool {
        do { return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) }
        catch { return false }
    }

    func scheduleExpirationNotifications(for item: EmergencyItem) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers(for: item))
        guard let expirationDate = item.expirationDate else { return }

        let isEnglish = UserDefaults.standard.string(forKey: "appLanguage") == AppLanguage.english.rawValue
        let reminders = [180, 90, 30, 7]

        for days in reminders {
            guard let rawDate = Calendar.current.date(byAdding: .day, value: -days, to: expirationDate) else { continue }
            var dateParts = Calendar.current.dateComponents([.year, .month, .day], from: rawDate)
            dateParts.hour = 9
            dateParts.minute = 0
            guard let reminderDate = Calendar.current.date(from: dateParts), reminderDate > .now else { continue }

            let label: String
            if isEnglish { label = days == 180 ? "6 months" : days == 90 ? "3 months" : "\(days) days" }
            else { label = days == 180 ? "6 μήνες" : days == 90 ? "3 μήνες" : "\(days) ημέρες" }

            let content = UNMutableNotificationContent()
            content.title = isEnglish ? "ReadyKit • Item expiration" : "ReadyKit • Λήξη προϊόντος"
            content.body = isEnglish ? "\(item.name) expires in \(label). Check it and plan a replacement." : "Το \(item.name) λήγει σε \(label). Έλεγξέ το και προγραμμάτισε αντικατάσταση."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateParts, repeats: false)
            let request = UNNotificationRequest(identifier: "expiration-\(item.id.uuidString)-\(days)", content: content, trigger: trigger)
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