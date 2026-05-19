import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    func scheduleReminders(feedingInterval: Int, sleepInterval: Int, diaperInterval: Int, lastFeeding: Date?, lastSleep: Date?, lastDiaper: Date?) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        if let lastFeeding = lastFeeding {
            let feedingDate = lastFeeding.addingTimeInterval(Double(feedingInterval) * 3600)
            if feedingDate > Date() {
                scheduleNotification(
                    id: "feeding_reminder",
                    title: "喂奶提醒",
                    body: "距离上次喂奶已超过\(feedingInterval)小时，建议尽快喂奶",
                    date: feedingDate
                )
            }
        }

        if let lastDiaper = lastDiaper {
            let diaperDate = lastDiaper.addingTimeInterval(Double(diaperInterval) * 3600)
            if diaperDate > Date() {
                scheduleNotification(
                    id: "diaper_reminder",
                    title: "尿布提醒",
                    body: "距离上次更换尿布已超过\(diaperInterval)小时，记得检查一下",
                    date: diaperDate
                )
            }
        }

        if let lastSleep = lastSleep {
            let sleepDate = lastSleep.addingTimeInterval(Double(sleepInterval) * 3600)
            if sleepDate > Date() {
                scheduleNotification(
                    id: "sleep_reminder",
                    title: "睡眠提醒",
                    body: "宝宝已清醒较久，建议准备入睡",
                    date: sleepDate
                )
            }
        }
    }

    private func scheduleNotification(id: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func getPendingCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.count
    }
}
