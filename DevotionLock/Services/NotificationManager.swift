//
//  NotificationManager.swift
//  DevotionLock
//

import Foundation
import UserNotifications

enum NotificationTone: String, CaseIterable, Identifiable {
    case gentle
    case direct

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gentle: "Gentle"
        case .direct: "Direct"
        }
    }
}

enum DevotionNotificationCategory: String {
    case morning
    case evening
    case streak
    case affirmation
    case prayerWall
    case answered
}

enum DevotionNotificationAction: String {
    case beginDevotion = "BEGIN_DEVOTION"
    case snoozeMorning = "SNOOZE_MORNING"
    case openJournal = "OPEN_JOURNAL"
    case openChaplain = "OPEN_CHAPLAIN"
    case startNow = "START_NOW"
    case remindTonight = "REMIND_TONIGHT"
    case prayNow = "PRAY_NOW"
    case markAnswered = "MARK_ANSWERED"
    case giveThanks = "GIVE_THANKS"
}

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private enum ID {
        static let morning = "devotion.morning"
        static let evening = "devotion.evening"
        static let streak = "devotion.streak"
        static let affirmation = "devotion.affirmation"
        static let prayerWall = "devotion.prayerWall"
    }

    private override init() {
        super.init()
    }

    func configure() {
        center.delegate = self
        registerCategories()
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Prompts for permission when needed, then turns on default morning reminders and schedules them.
    @discardableResult
    func requestAuthorizationEnablingDefaults() async -> Bool {
        configure()
        let status = await authorizationStatus()
        let granted: Bool
        switch status {
        case .authorized, .provisional, .ephemeral:
            granted = true
        case .notDetermined:
            granted = await requestAuthorization()
        case .denied:
            granted = false
        @unknown default:
            granted = false
        }

        if granted {
            UserDefaults.standard.set(true, forKey: "morningReminderEnabled")
            rescheduleAll()
        }
        return granted
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func rescheduleAll() {
        let morningEnabled = UserDefaults.standard.bool(forKey: "morningReminderEnabled")
        let eveningEnabled = UserDefaults.standard.bool(forKey: "eveningReminderEnabled")
        let streakEnabled = UserDefaults.standard.object(forKey: "streakNudgeEnabled") as? Bool ?? true
        let affirmationEnabled = UserDefaults.standard.object(forKey: "affirmationEnabled") as? Bool ?? true
        let prayerWallEnabled = UserDefaults.standard.object(forKey: "prayerWallReminderEnabled") as? Bool ?? false
        let tone = NotificationTone(rawValue: UserDefaults.standard.string(forKey: "notificationTone") ?? "") ?? .gentle

        center.removeAllPendingNotificationRequests()

        if morningEnabled {
            scheduleMorning(at: storedTime(key: "morningReminderTime", defaultHour: 7, defaultMinute: 0), tone: tone)
        }
        if eveningEnabled {
            scheduleEvening(at: storedTime(key: "eveningReminderTime", defaultHour: 18, defaultMinute: 0), tone: tone)
        }
        if streakEnabled {
            scheduleStreakNudge(at: DateComponents(hour: 14, minute: 30), tone: tone)
        }
        if affirmationEnabled {
            scheduleAffirmation(at: DateComponents(hour: 12, minute: 0), tone: tone)
        }
        if prayerWallEnabled {
            schedulePrayerWallWeekly(tone: tone)
        }
    }

    func postAnsweredPrayerCelebration(text: String) {
        let tone = NotificationTone(rawValue: UserDefaults.standard.string(forKey: "notificationTone") ?? "") ?? .gentle
        let content = UNMutableNotificationContent()
        content.title = tone == .gentle ? "Praise — an answered prayer" : "Answered! 🙌"
        content.body = tone == .gentle
            ? "Give thanks for: \"\(text)\""
            : "You marked this answered: \"\(text)\""
        content.sound = .default
        content.categoryIdentifier = DevotionNotificationCategory.answered.rawValue
        content.userInfo = ["route": "prayer-wall"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "devotion.answered.\(UUID().uuidString)", content: content, trigger: trigger)
        center.add(request)
    }

    func previewContent(for kind: DevotionNotificationCategory, tone: NotificationTone) -> (title: String, body: String) {
        let quote = LoadingQuoteCatalog.today
        switch kind {
        case .morning:
            return tone == .gentle
                ? ("Your morning sanctuary is ready", "“\(quote.text)” — \(quote.reference)")
                : ("Don't miss today's devotion", "Your \(StreakManager.shared.currentStreak)-day streak is on the line.")
        case .evening:
            return tone == .gentle
                ? ("A quiet moment before sleep", "How did God show up today?")
                : ("Evening reflection", "Close the day — journal before bed.")
        case .streak:
            return tone == .gentle
                ? ("Your streak is waiting", "A few minutes with God still counts.")
                : ("Streak alert", "\(StreakManager.shared.currentStreak) days strong — keep it going.")
        case .affirmation:
            return ("A word for today", "“\(quote.text)”")
        case .prayerWall:
            return tone == .gentle
                ? ("Someone on your wall", "Pause and pray for what's pinned.")
                : ("Prayer wall check-in", "Active requests need you today.")
        case .answered:
            return ("Praise — an answered prayer", "Give thanks for what God has done.")
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let route = userInfo["route"] as? String
        let action = DevotionNotificationAction(rawValue: response.actionIdentifier)

        await MainActor.run {
            DeepLinkRouter.shared.handleNotificationAction(action, route: route)
        }
    }

    private func registerCategories() {
        let morning = UNNotificationCategory(
            identifier: DevotionNotificationCategory.morning.rawValue,
            actions: [
                UNNotificationAction(identifier: DevotionNotificationAction.beginDevotion.rawValue, title: "Begin devotion", options: [.foreground]),
                UNNotificationAction(identifier: DevotionNotificationAction.snoozeMorning.rawValue, title: "Snooze 15m", options: []),
            ],
            intentIdentifiers: []
        )
        let evening = UNNotificationCategory(
            identifier: DevotionNotificationCategory.evening.rawValue,
            actions: [
                UNNotificationAction(identifier: DevotionNotificationAction.openJournal.rawValue, title: "Open journal", options: [.foreground]),
                UNNotificationAction(identifier: DevotionNotificationAction.openChaplain.rawValue, title: "Talk with Chaplain", options: [.foreground]),
            ],
            intentIdentifiers: []
        )
        let streak = UNNotificationCategory(
            identifier: DevotionNotificationCategory.streak.rawValue,
            actions: [
                UNNotificationAction(identifier: DevotionNotificationAction.startNow.rawValue, title: "Start now", options: [.foreground]),
                UNNotificationAction(identifier: DevotionNotificationAction.remindTonight.rawValue, title: "Remind tonight", options: []),
            ],
            intentIdentifiers: []
        )
        let prayerWall = UNNotificationCategory(
            identifier: DevotionNotificationCategory.prayerWall.rawValue,
            actions: [
                UNNotificationAction(identifier: DevotionNotificationAction.prayNow.rawValue, title: "Pray now", options: [.foreground]),
                UNNotificationAction(identifier: DevotionNotificationAction.markAnswered.rawValue, title: "Mark answered", options: [.foreground]),
            ],
            intentIdentifiers: []
        )
        let answered = UNNotificationCategory(
            identifier: DevotionNotificationCategory.answered.rawValue,
            actions: [
                UNNotificationAction(identifier: DevotionNotificationAction.giveThanks.rawValue, title: "Give thanks", options: [.foreground]),
            ],
            intentIdentifiers: []
        )
        let affirmation = UNNotificationCategory(
            identifier: DevotionNotificationCategory.affirmation.rawValue,
            actions: [
                UNNotificationAction(identifier: DevotionNotificationAction.openChaplain.rawValue, title: "Reflect", options: [.foreground]),
            ],
            intentIdentifiers: []
        )
        center.setNotificationCategories([morning, evening, streak, prayerWall, answered, affirmation])
    }

    private func scheduleMorning(at components: DateComponents, tone: NotificationTone) {
        let copy = previewContent(for: .morning, tone: tone)
        schedule(
            id: ID.morning,
            title: copy.title,
            body: copy.body,
            components: components,
            category: .morning,
            route: "journal"
        )
    }

    private func scheduleEvening(at components: DateComponents, tone: NotificationTone) {
        let copy = previewContent(for: .evening, tone: tone)
        schedule(
            id: ID.evening,
            title: copy.title,
            body: copy.body,
            components: components,
            category: .evening,
            route: "journal"
        )
    }

    private func scheduleStreakNudge(at components: DateComponents, tone: NotificationTone) {
        let copy = previewContent(for: .streak, tone: tone)
        schedule(
            id: ID.streak,
            title: copy.title,
            body: copy.body,
            components: components,
            category: .streak,
            route: "journal"
        )
    }

    private func scheduleAffirmation(at components: DateComponents, tone: NotificationTone) {
        let copy = previewContent(for: .affirmation, tone: tone)
        schedule(
            id: ID.affirmation,
            title: copy.title,
            body: copy.body,
            components: components,
            category: .affirmation,
            route: "chaplain"
        )
    }

    private func schedulePrayerWallWeekly(tone: NotificationTone) {
        let copy = previewContent(for: .prayerWall, tone: tone)
        let components = DateComponents(hour: 10, minute: 0, weekday: 1)
        schedule(
            id: ID.prayerWall,
            title: copy.title,
            body: copy.body,
            components: components,
            category: .prayerWall,
            route: "prayer-wall"
        )
    }

    private func schedule(
        id: String,
        title: String,
        body: String,
        components: DateComponents,
        category: DevotionNotificationCategory,
        route: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category.rawValue
        content.userInfo = ["route": route]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    private func storedTime(key: String, defaultHour: Int, defaultMinute: Int) -> DateComponents {
        let raw = UserDefaults.standard.string(forKey: key) ?? ""
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: raw) {
            let calendar = Calendar.current
            return DateComponents(
                hour: calendar.component(.hour, from: date),
                minute: calendar.component(.minute, from: date)
            )
        }
        return DateComponents(hour: defaultHour, minute: defaultMinute)
    }
}
