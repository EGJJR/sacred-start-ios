//
//  DeepLinkRouter.swift
//  DevotionLock
//

import Foundation
import SwiftUI
import UserNotifications

@MainActor
@Observable
final class DeepLinkRouter {
    static let shared = DeepLinkRouter()

    var pendingRoute: DeepLinkRoute?

    enum DeepLinkRoute: Equatable {
        case home
        case journal
        case chaplain(prompt: String?)
        case prayerWall(addKind: String?, openCircles: Bool = false, joinCode: String? = nil)
        case streak
    }

    func handle(url: URL) {
        guard let parsed = DevotionDeepLink.parse(url) else { return }
        switch parsed.host {
        case .home:
            pendingRoute = .home
        case .journal:
            pendingRoute = .journal
        case .chaplain:
            pendingRoute = .chaplain(prompt: parsed.query["prompt"])
        case .prayerWall:
            pendingRoute = .prayerWall(addKind: parsed.query["kind"])
        case .streak:
            pendingRoute = .streak
        case .addPrayer:
            pendingRoute = .prayerWall(addKind: parsed.query["kind"] ?? "request")
        case .joinCircle:
            pendingRoute = .prayerWall(addKind: nil, openCircles: true, joinCode: parsed.query["code"])
        }
    }

    func handleNotificationAction(_ action: DevotionNotificationAction?, route: String?) {
        switch action {
        case .beginDevotion, .startNow, .openJournal:
            pendingRoute = .journal
        case .openChaplain, .giveThanks:
            pendingRoute = .chaplain(prompt: nil)
        case .prayNow, .markAnswered:
            pendingRoute = .prayerWall(addKind: nil)
        case .snoozeMorning:
            scheduleSnooze(minutes: 15, route: route)
        case .remindTonight:
            scheduleSnooze(minutes: 360, route: route)
        case .none:
            if route == "journal" { pendingRoute = .journal }
            else if route == "chaplain" { pendingRoute = .chaplain(prompt: nil) }
            else if route == "prayer-wall" { pendingRoute = .prayerWall(addKind: nil) }
            else if route == "streak" { pendingRoute = .streak }
        }
    }

    func consumePendingRoute() -> DeepLinkRoute? {
        defer { pendingRoute = nil }
        if let pendingRoute { return pendingRoute }
        if let action = PendingWidgetActionStore.consume() {
            switch action {
            case .addPrayerRequest: return .prayerWall(addKind: "request")
            case .addReminder: return .prayerWall(addKind: "reminder")
            case .addAnsweredPrayer: return .prayerWall(addKind: "answered")
            case .openPrayerWall: return .prayerWall(addKind: nil)
            }
        }
        return nil
    }

    private func scheduleSnooze(minutes: Int, route: String?) {
        let content = UNMutableNotificationContent()
        content.title = "Gentle reminder"
        content.body = "Your sanctuary is still here when you're ready."
        content.sound = .default
        content.userInfo = ["route": route ?? "journal"]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "devotion.snooze.\(UUID().uuidString)", content: content, trigger: trigger)
        )
    }
}

struct DeepLinkHandlerModifier: ViewModifier {
    @State private var router = DeepLinkRouter.shared
    var onRoute: (DeepLinkRouter.DeepLinkRoute) -> Void

    func body(content: Content) -> some View {
        content
            .onOpenURL { router.handle(url: $0) }
            .onChange(of: router.pendingRoute) { _, route in
                guard route != nil, let consumed = router.consumePendingRoute() else { return }
                onRoute(consumed)
            }
            .onAppear {
                if let route = router.consumePendingRoute() {
                    onRoute(route)
                }
            }
    }
}

extension View {
    func handleDevotionDeepLinks(onRoute: @escaping (DeepLinkRouter.DeepLinkRoute) -> Void) -> some View {
        modifier(DeepLinkHandlerModifier(onRoute: onRoute))
    }
}
