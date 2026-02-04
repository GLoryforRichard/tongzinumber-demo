//
//  ReminderData.swift
//  tongzinumber-demo
//
//  Created by Richard Liu on 2026-02-03.
//

import Foundation

final class ReminderData {
    static let shared = ReminderData()

    private static let appGroupIdentifier = "group.cupicelemon.tongzinumber-demo"
    private static let lastScheduledSecondsKey = "lastScheduledSeconds"
    private static let nextReminderSecondsKey = "nextReminderSeconds"

    private let userDefaults: UserDefaults?

    private init() {
        userDefaults = UserDefaults(suiteName: Self.appGroupIdentifier)
    }

    var lastScheduledSeconds: Int {
        get {
            userDefaults?.integer(forKey: Self.lastScheduledSecondsKey) ?? 60
        }
        set {
            userDefaults?.set(newValue, forKey: Self.lastScheduledSecondsKey)
        }
    }

    var nextReminderSeconds: Int {
        get {
            userDefaults?.integer(forKey: Self.nextReminderSecondsKey) ?? 60
        }
        set {
            userDefaults?.set(newValue, forKey: Self.nextReminderSecondsKey)
        }
    }
}
