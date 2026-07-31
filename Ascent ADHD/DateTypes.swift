//
//  DateTypes.swift
//  Ascent ADHD
//
//  Lightweight value types mirroring java.time.LocalDate / LocalTime / YearMonth so the port keeps
//  the same wall-clock (timezone-free) date semantics — and so the persisted JSON uses the exact
//  same ISO strings the Android app writes (making a backup file cross-compatible).
//

import Foundation

// A calendar that treats stored Y/M/D as fixed wall-clock values (UTC-anchored for stable math).
private let utcCalendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}()

// MARK: - CalDate  (LocalDate)

struct CalDate: Codable, Hashable, Comparable, CustomStringConvertible {
    var year: Int
    var month: Int
    var day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year; self.month = month; self.day = day
    }

    /// From a real Date, using the user's *local* calendar day (matches LocalDate.now()).
    init(_ date: Date) {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        year = comps.year ?? 1970
        month = comps.month ?? 1
        day = comps.day ?? 1
    }

    static func today() -> CalDate { CalDate(Date()) }

    /// Noon UTC of this day — a stable anchor for arithmetic and formatting.
    var anchor: Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day; comps.hour = 12
        return utcCalendar.date(from: comps) ?? Date(timeIntervalSince1970: 0)
    }

    var epochDay: Int64 {
        Int64(floor(anchor.timeIntervalSince1970 / 86_400))
    }

    static func fromEpochDay(_ ed: Int64) -> CalDate {
        let date = Date(timeIntervalSince1970: TimeInterval(ed) * 86_400 + 43_200) // + noon
        let comps = utcCalendar.dateComponents([.year, .month, .day], from: date)
        return CalDate(year: comps.year ?? 1970, month: comps.month ?? 1, day: comps.day ?? 1)
    }

    func plusDays(_ n: Int) -> CalDate {
        CalDate.fromEpochDay(epochDay + Int64(n))
    }

    func minusDays(_ n: Int) -> CalDate { plusDays(-n) }

    func isAfter(_ other: CalDate) -> Bool { self > other }
    func isBefore(_ other: CalDate) -> Bool { self < other }

    /// 1 = Monday … 7 = Sunday (matches DayOfWeek.value).
    var dayOfWeekValue: Int {
        let wd = utcCalendar.component(.weekday, from: anchor) // 1 = Sun … 7 = Sat
        return wd == 1 ? 7 : wd - 1
    }

    var dayOfMonth: Int { day }

    /// Most recent Monday on or before this date.
    var previousOrSameMonday: CalDate { minusDays(dayOfWeekValue - 1) }

    // ISO "yyyy-MM-dd" — the exact format LocalDate.toString() produces.
    var iso: String { String(format: "%04d-%02d-%02d", year, month, day) }
    var description: String { iso }

    static func parse(_ s: String?) -> CalDate? {
        guard let s = s, !s.isEmpty else { return nil }
        let parts = s.split(separator: "-")
        guard parts.count == 3, let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) else { return nil }
        return CalDate(year: y, month: m, day: d)
    }

    static func < (lhs: CalDate, rhs: CalDate) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }

    // Formatting helpers.
    private func formatted(_ template: String) -> String {
        let f = DateFormatter()
        f.calendar = utcCalendar
        f.timeZone = utcCalendar.timeZone
        f.locale = Locale.current
        f.dateFormat = template
        return f.string(from: anchor)
    }

    var weekdayNarrow: String {   // M / T / W …
        let names = ["M", "T", "W", "T", "F", "S", "S"]
        return names[(dayOfWeekValue - 1) % 7]
    }
    var weekdayShort: String { formatted("EEE") }      // Mon
    var weekdayFull: String { formatted("EEEE") }      // Monday
    var monthFull: String { formatted("MMMM") }        // January
    var monthShort: String { formatted("MMM") }        // Jan
}

// MARK: - CalTime  (LocalTime)

struct CalTime: Codable, Hashable, Comparable, CustomStringConvertible {
    var hour: Int
    var minute: Int

    // ISO "HH:mm" — LocalTime.toString() drops seconds when zero; we always write HH:mm.
    var iso: String { String(format: "%02d:%02d", hour, minute) }
    var description: String { iso }

    static func parse(_ s: String?) -> CalTime? {
        guard let s = s, !s.isEmpty else { return nil }
        let parts = s.split(separator: ":")
        guard parts.count >= 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return CalTime(hour: h, minute: m)
    }

    static func < (lhs: CalTime, rhs: CalTime) -> Bool {
        lhs.hour != rhs.hour ? lhs.hour < rhs.hour : lhs.minute < rhs.minute
    }
}

// MARK: - CalMonth  (YearMonth)

struct CalMonth: Codable, Hashable, Comparable, CustomStringConvertible {
    var year: Int
    var month: Int

    static func now() -> CalMonth { let t = CalDate.today(); return CalMonth(year: t.year, month: t.month) }

    func plusMonths(_ n: Int) -> CalMonth {
        let total = year * 12 + (month - 1) + n
        return CalMonth(year: total / 12, month: total % 12 + 1)
    }
    func minusMonths(_ n: Int) -> CalMonth { plusMonths(-n) }

    func atDay(_ d: Int) -> CalDate { CalDate(year: year, month: month, day: d) }
    var lengthOfMonth: Int {
        let comps = DateComponents(year: year, month: month)
        guard let date = utcCalendar.date(from: comps),
              let range = utcCalendar.range(of: .day, in: .month, for: date) else { return 30 }
        return range.count
    }
    var firstDayOfWeekValue: Int { atDay(1).dayOfWeekValue }

    func isAfter(_ other: CalMonth) -> Bool { self > other }

    // ISO "yyyy-MM" — matches YearMonth.toString().
    var iso: String { String(format: "%04d-%02d", year, month) }
    var description: String { iso }

    static func parse(_ s: String?) -> CalMonth? {
        guard let s = s, !s.isEmpty else { return nil }
        let parts = s.split(separator: "-")
        guard parts.count >= 2, let y = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return CalMonth(year: y, month: m)
    }

    static func < (lhs: CalMonth, rhs: CalMonth) -> Bool {
        lhs.year != rhs.year ? lhs.year < rhs.year : lhs.month < rhs.month
    }

    var monthFull: String { atDay(1).monthFull }
}
