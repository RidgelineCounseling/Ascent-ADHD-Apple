//
//  Reminders.swift
//  Ascent ADHD
//
//  iOS local-notification scheduling — the EventKit/AlarmManager equivalent of the Android
//  ReminderReceiver + scheduleReminder/scheduleReflectionReminder flow. Uses UNUserNotificationCenter.
//

import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

enum Reminders {

    static let reflectionId = "ridgeline_reflection_daily"

    /// Ask for notification permission once (call at launch).
    static func requestAuthorization() {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        #endif
    }

    /// Schedule (or cancel) the daily reflection reminder at the given time.
    static func scheduleReflection(enabled: Bool, hour: Int, minute: Int) {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reflectionId])
        guard enabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "A moment to reflect"
        content.body = "Take a breath and note how today went."
        content.sound = .default
        var comps = DateComponents()
        comps.hour = hour; comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: reflectionId, content: content, trigger: trigger))
        #endif
    }

    /// Schedule a one-off reminder for a specific item at a wall-clock date.
    static func scheduleReminder(itemId: String, slot: String = "specific", title: String, body: String, at date: Date) {
        #if canImport(UserNotifications)
        guard date > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let id = requestId(itemId, slot)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        #endif
    }

    static func cancelReminder(itemId: String, slot: String = "specific") {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [requestId(itemId, slot)])
        #endif
    }

    static func cancelAllReminders(itemId: String) {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["specific", "morning", "night"].map { requestId(itemId, $0) })
        #endif
    }

    private static func requestId(_ itemId: String, _ slot: String) -> String { "reminder_\(itemId)_\(slot)" }
}

// MARK: - Reminder time helpers (ported from nightBeforeEpochMillis / morningOfEpochMillis / formatReminderLabel)

/// 8 PM the night before the item's date, or nil if that's already in the past.
func nightBeforeDate(_ itemDate: CalDate) -> Date? {
    let prev = itemDate.minusDays(1)
    var comps = DateComponents()
    comps.year = prev.year; comps.month = prev.month; comps.day = prev.day; comps.hour = 20; comps.minute = 0
    guard let d = Calendar.current.date(from: comps), d > Date() else { return nil }
    return d
}

/// 9 AM the morning of the item's date, or nil if that's already in the past.
func morningOfDate(_ itemDate: CalDate) -> Date? {
    var comps = DateComponents()
    comps.year = itemDate.year; comps.month = itemDate.month; comps.day = itemDate.day; comps.hour = 9; comps.minute = 0
    guard let d = Calendar.current.date(from: comps), d > Date() else { return nil }
    return d
}

func formatReminderLabel(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "MMM d, h:mm a"
    return f.string(from: date)
}
