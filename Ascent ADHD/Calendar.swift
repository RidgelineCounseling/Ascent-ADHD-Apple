//
//  Calendar.swift
//  Ascent ADHD
//
//  Read-only device-calendar access via EventKit — the iOS equivalent of the Android
//  CalendarContract queries. Events are transient (never persisted into the app's own data).
//

import Foundation
import EventKit

struct ExternalEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let isAllDay: Bool
    let startHour: Int
    let startMinute: Int
    let calendarColorArgb: UInt32
}

final class CalendarService {
    static let shared = CalendarService()
    private let store = EKEventStore()

    var isAuthorized: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) { return status == .fullAccess }
        return status == .authorized
    }

    /// Request read access. iOS 17+ uses full-access; earlier uses the legacy request.
    func requestAccess(_ completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            store.requestFullAccessToEvents { granted, _ in DispatchQueue.main.async { completion(granted) } }
        } else {
            store.requestAccess(to: .event) { granted, _ in DispatchQueue.main.async { completion(granted) } }
        }
    }

    /// Events on the given calendar day, sorted by start time.
    func events(on date: CalDate) -> [ExternalEvent] {
        guard isAuthorized else { return [] }
        let cal = Calendar.current
        guard let dayStart = cal.date(from: DateComponents(year: date.year, month: date.month, day: date.day)),
              let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return [] }
        let predicate = store.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: nil)
        return store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map { ev in
                let comps = cal.dateComponents([.hour, .minute], from: ev.startDate)
                return ExternalEvent(
                    id: ev.eventIdentifier ?? UUID().uuidString,
                    title: ev.title ?? "(no title)",
                    isAllDay: ev.isAllDay,
                    startHour: comps.hour ?? 0,
                    startMinute: comps.minute ?? 0,
                    calendarColorArgb: 0xFFA3B8C9
                )
            }
    }
}
