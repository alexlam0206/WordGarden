// All changes after that commit have been discarded, and the working directory is now at that state.

import Foundation
import UserNotifications

// Manages scheduling of local notifications.
class NotificationManager {
    static let shared = NotificationManager()

    // Requests authorization to send notifications.
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification authorization granted.")
            } else if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }

    private let notificationTemplates = [
        (title: "Time to Grow!", body: "Your WordGarden is waiting. Come learn a new word!"),
        (title: "Feeling Curious?", body: "Discover a new word and watch your garden flourish."),
        (title: "Water Your Words!", body: "A quick review session will help your vocabulary grow."),
        (title: "Don't Forget Your Garden!", body: "Your words miss you. It's time to learn!"),
        (title: "Ready for a Challenge?", body: "A new word is ready to be planted in your garden.")
    ]

    // Schedules a daily notification at the specified time.
    func scheduleDailyNotification(at time: Date) {
        let content = UNMutableNotificationContent()
        let template = notificationTemplates.randomElement()!
        content.title = template.title
        content.body = template.body
        content.sound = .default

        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        dateComponents.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "wordgarden-daily-notification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Daily notification scheduled successfully.")
            }
        }
    }

    // Cancels all scheduled notifications.
    func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("All pending notifications cancelled.")
    }
}
