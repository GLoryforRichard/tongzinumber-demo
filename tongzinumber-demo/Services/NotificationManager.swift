//
//  NotificationManager.swift
//  tongzinumber-demo
//
//  Created by Richard Liu on 2026-02-03.
//

import Foundation
import UserNotifications

final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    static let categoryIdentifier = "TIMER_REMINDER"
    static let confirmActionIdentifier = "CONFIRM_ACTION"

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private override init() {
        super.init()
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await updateAuthorizationStatus()
            return granted
        } catch {
            return false
        }
    }

    @MainActor
    func updateAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func registerCategory() {
        let confirmAction = UNNotificationAction(
            identifier: Self.confirmActionIdentifier,
            title: "确认",
            options: [.foreground]
        )

        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [confirmAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func scheduleNotification(seconds: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "定时提醒"
        content.body = "时间到了！下拉或长按选择下一次提醒时间"
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier
        content.userInfo = ["scheduledSeconds": seconds]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)

        ReminderData.shared.lastScheduledSeconds = seconds
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
