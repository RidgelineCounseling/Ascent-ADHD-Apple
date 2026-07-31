//
//  AppStore.swift
//  Ascent ADHD
//
//  The single source of truth — ports the state + persistence block of MainApp. Data is stored in
//  UserDefaults as JSON under the same keys the Android app uses (SharedPreferences "ridgeline_storage_v7"),
//  and the gamification engine (elevation / milestones / rhythm) is reproduced faithfully.
//

import SwiftUI
import Combine

struct AscentEvent: Equatable {
    var before: Int
    var after: Int
    var taskLabel: String
}

final class AppStore: ObservableObject {

    private static let suiteName = "ridgeline_storage_v7"
    private let defaults = UserDefaults(suiteName: AppStore.suiteName) ?? .standard

    // MARK: Persisted collections
    @Published var scheduleEntries: [ScheduleEntry] = []      { didSet { saveList("scheduleEntries", scheduleEntries) { $0.toJSON() } } }
    @Published var otherTodoEntries: [OtherTodoItem] = []     { didSet { saveList("otherTodoEntries", otherTodoEntries) { $0.toJSON() } } }
    @Published var insightLogs: [InsightLog] = []             { didSet { saveList("insightLogs", insightLogs) { $0.toJSON() } } }
    @Published var goalEntries: [GoalEntry] = []              { didSet { saveList("goalEntries", goalEntries) { $0.toJSON() } } }
    @Published var reflectionEntries: [ReflectionEntry] = []  { didSet { saveList("reflectionEntries", reflectionEntries) { $0.toJSON() } } }

    // Map of grand (end-of-day) rewards keyed by date.
    @Published var dailyGrandRewards: [CalDate: String] = [:] { didSet { saveGrandRewards() } }

    // MARK: Scalars & gamification
    @Published var elevation: Int = 0                { didSet { defaults.set(elevation, forKey: "elevation") } }
    @Published var todayCompletions: Int = 0
    @Published var activityDates: Set<Int64> = []    { didSet { saveActivityDates() } }
    @Published var points: Int = 0                   { didSet { defaults.set(points, forKey: "points") } }
    @Published var streak: Int = 0                   { didSet { defaults.set(streak, forKey: "streak") } }
    @Published var freezes: Int = 0                  { didSet { defaults.set(freezes, forKey: "freezes") } }

    // MARK: Reward bank & onboarding
    @Published var rewardBank: RewardBank = .empty   { didSet { saveRewardBank() } }
    @Published var hasCompletedSetup: Bool = false   { didSet { defaults.set(hasCompletedSetup, forKey: "hasCompletedSetup") } }
    @Published var heatmapWindow: String = "30"      { didSet { defaults.set(heatmapWindow, forKey: "heatmapWindow") } }

    // MARK: Trail notes journey
    @Published var journeyStage: String = TRAIL_STAGE_FOUNDATION { didSet { defaults.set(journeyStage, forKey: "journeyStage") } }
    @Published var trailNotesSeen: Set<String> = []  { didSet { defaults.set(Array(trailNotesSeen), forKey: "trailNotesSeen") } }
    @Published var hasSetJourneyStage: Bool = false  { didSet { defaults.set(hasSetJourneyStage, forKey: "hasSetJourneyStage") } }

    // MARK: Reflection reminder settings
    @Published var reflectionReminderEnabled: Bool = true { didSet { defaults.set(reflectionReminderEnabled, forKey: "reflectionReminderEnabled"); rescheduleReflection() } }
    @Published var reflectionReminderHour: Int = 20       { didSet { defaults.set(reflectionReminderHour, forKey: "reflectionReminderHour"); rescheduleReflection() } }
    @Published var reflectionReminderMinute: Int = 0      { didSet { defaults.set(reflectionReminderMinute, forKey: "reflectionReminderMinute"); rescheduleReflection() } }

    // MARK: Transient celebration / banner state
    @Published var celebrationMilestone: Milestone? = nil
    @Published var ascentCelebration: AscentEvent? = nil
    @Published var customNotification: CustomNotificationData? = nil

    // MARK: Focus session (delay-aversion chunking)
    @Published var focusSession: FocusSession? = nil
    @Published var focusChunkReward: String? = nil

    // MARK: Device calendar opt-in
    @Published var showDeviceCalendar: Bool = false { didSet { defaults.set(showDeviceCalendar, forKey: "showDeviceCalendar") } }

    private var todayCompletionsDay: Int64 = 0

    // MARK: - Load

    init() { load() }

    private func load() {
        scheduleEntries  = loadList("scheduleEntries") { ScheduleEntry.from($0) }
        otherTodoEntries = loadList("otherTodoEntries") { OtherTodoItem.from($0) }
        insightLogs      = loadList("insightLogs") { InsightLog.from($0) }
        goalEntries      = loadList("goalEntries") { GoalEntry.from($0) }
        reflectionEntries = loadList("reflectionEntries") { ReflectionEntry.from($0) }
        dailyGrandRewards = loadGrandRewards()
        activityDates    = loadActivityDates()

        elevation = defaults.integer(forKey: "elevation")
        points = defaults.integer(forKey: "points")
        streak = defaults.integer(forKey: "streak")
        freezes = defaults.integer(forKey: "freezes")

        let storedDay = Int64(defaults.integer(forKey: "todayCompletionsDay"))
        let today = CalDate.today().epochDay
        todayCompletionsDay = storedDay
        todayCompletions = storedDay == today ? defaults.integer(forKey: "todayCompletions") : 0

        rewardBank = loadRewardBank()
        hasCompletedSetup = defaults.bool(forKey: "hasCompletedSetup")
        heatmapWindow = defaults.string(forKey: "heatmapWindow") ?? "30"
        journeyStage = defaults.string(forKey: "journeyStage") ?? TRAIL_STAGE_FOUNDATION
        trailNotesSeen = Set((defaults.array(forKey: "trailNotesSeen") as? [String]) ?? [])
        hasSetJourneyStage = defaults.bool(forKey: "hasSetJourneyStage")

        reflectionReminderEnabled = defaults.object(forKey: "reflectionReminderEnabled") as? Bool ?? true
        reflectionReminderHour = defaults.object(forKey: "reflectionReminderHour") as? Int ?? 20
        reflectionReminderMinute = defaults.integer(forKey: "reflectionReminderMinute")
        showDeviceCalendar = defaults.bool(forKey: "showDeviceCalendar")
    }

    // MARK: - Focus session (ported from the focus ticker + overlay)

    func startFocus(taskLabel: String, minutes: Int) {
        focusChunkReward = nil
        focusSession = FocusSession(taskLabel: taskLabel, workMinutes: minutes)
    }

    /// One-second tick. Decrements the current phase; on a boundary, transitions work↔break,
    /// awarding elevation + surfacing a micro-reward at the end of each work chunk.
    func tickFocus() {
        guard var s = focusSession, !s.isPaused else { return }
        if s.secondsLeft > 1 {
            s.secondsLeft -= 1
            focusSession = s
            return
        }
        if s.phase == FOCUS_PHASE_WORK {
            awardElevation(ELEVATION_TODO, message: "Focus chunk done · +\(ELEVATION_TODO) ft", silent: true)
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            focusChunkReward = rewardBank.small.randomElement()
            s.phase = FOCUS_PHASE_BREAK
            s.secondsLeft = FOCUS_BREAK_MINUTES * 60
            s.chunksCompleted += 1
            focusSession = s
        } else {
            focusChunkReward = nil
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            s.phase = FOCUS_PHASE_WORK
            s.secondsLeft = s.workMinutes * 60
            focusSession = s
        }
    }

    func toggleFocusPause() {
        guard var s = focusSession else { return }
        s.isPaused.toggle(); focusSession = s
    }

    func skipBreak() {
        guard var s = focusSession else { return }
        focusChunkReward = nil
        s.phase = FOCUS_PHASE_WORK; s.secondsLeft = s.workMinutes * 60
        focusSession = s
    }

    func stopFocus() {
        let done = focusSession?.chunksCompleted ?? 0
        focusSession = nil
        focusChunkReward = nil
        if done > 0 {
            showNotification("Focus done", "\(done) chunk\(done == 1 ? "" : "s") completed. Nice work.", color: RidgelineBlue, icon: "⛰️")
        }
    }

    // MARK: - Gamification engine (ported from awardElevation / removeElevation / recordActivity)

    /// Record today for the 7-day rhythm view (idempotent).
    func recordActivity() {
        let today = CalDate.today().epochDay
        if !activityDates.contains(today) { activityDates.insert(today) }
    }

    /// Increment today's completion counter, resetting first if the stored day is stale.
    func bumpTodayCompletions() {
        let today = CalDate.today().epochDay
        todayCompletions = (todayCompletionsDay == today) ? todayCompletions + 1 : 1
        todayCompletionsDay = today
        defaults.set(Int(today), forKey: "todayCompletionsDay")
        defaults.set(todayCompletions, forKey: "todayCompletions")
    }

    /// Award elevation for a completion. Adds the amount, records activity, bumps the daily tier,
    /// and fires either a milestone celebration or a routine ascent celebration.
    func awardElevation(_ amount: Int, message: String, silent: Bool = false) {
        let before = elevation
        elevation += amount
        recordActivity()
        bumpTodayCompletions()

        if let crossed = MILESTONE_LADDER.first(where: { $0.threshold > before && $0.threshold <= elevation }) {
            celebrationMilestone = crossed
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        } else if !silent {
            ascentCelebration = AscentEvent(before: before, after: elevation, taskLabel: message)
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
    }

    /// Reverse an award when an item is unchecked. Floor at 0; does not un-earn milestones/rhythm.
    func removeElevation(_ amount: Int) {
        elevation = max(elevation - amount, 0)
        if todayCompletions > 0 {
            todayCompletions -= 1
            defaults.set(todayCompletions, forKey: "todayCompletions")
        }
    }

    func showNotification(_ title: String, _ message: String, color: Color, icon: String) {
        customNotification = CustomNotificationData(title: title, message: message, bgColor: color, icon: icon)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            self?.customNotification = nil
        }
    }

    private func rescheduleReflection() {
        // iOS local-notification scheduling lives in Reminders.swift (UNUserNotificationCenter).
        Reminders.scheduleReflection(enabled: reflectionReminderEnabled,
                                     hour: reflectionReminderHour, minute: reflectionReminderMinute)
    }

    // MARK: - Persistence helpers

    private func saveList<T>(_ key: String, _ items: [T], _ toJSON: (T) -> [String: Any]) {
        let arr = items.map(toJSON)
        if let data = try? JSONSerialization.data(withJSONObject: arr),
           let str = String(data: data, encoding: .utf8) {
            defaults.set(str, forKey: key)
        }
    }
    private func loadList<T>(_ key: String, _ from: ([String: Any]) -> T) -> [T] {
        guard let str = defaults.string(forKey: key), let data = str.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return arr.map(from)
    }

    private func saveGrandRewards() {
        var obj: [String: String] = [:]
        for (date, reward) in dailyGrandRewards { obj[date.iso] = reward }
        if let data = try? JSONSerialization.data(withJSONObject: obj), let s = String(data: data, encoding: .utf8) {
            defaults.set(s, forKey: "dailyGrandRewards")
        }
    }
    private func loadGrandRewards() -> [CalDate: String] {
        guard let s = defaults.string(forKey: "dailyGrandRewards"), let data = s.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        var out: [CalDate: String] = [:]
        for (k, v) in obj { if let d = CalDate.parse(k) { out[d] = v as? String ?? "" } }
        return out
    }

    private func saveActivityDates() {
        let arr = activityDates.sorted().map { NSNumber(value: $0) }
        if let data = try? JSONSerialization.data(withJSONObject: arr), let s = String(data: data, encoding: .utf8) {
            defaults.set(s, forKey: "activityDates")
        }
    }
    private func loadActivityDates() -> Set<Int64> {
        guard let s = defaults.string(forKey: "activityDates"), let data = s.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [NSNumber] else { return [] }
        return Set(arr.map { $0.int64Value })
    }

    private func saveRewardBank() {
        let obj: [String: Any] = ["small": rewardBank.small, "medium": rewardBank.medium]
        if let data = try? JSONSerialization.data(withJSONObject: obj), let s = String(data: data, encoding: .utf8) {
            defaults.set(s, forKey: "rewardBank")
        }
    }
    private func loadRewardBank() -> RewardBank {
        guard let s = defaults.string(forKey: "rewardBank"), let data = s.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return .empty }
        let small = (obj["small"] as? [String]) ?? []
        let medium = (obj["medium"] as? [String]) ?? []
        return RewardBank(small: small, medium: medium)
    }

    // MARK: - Convenience mutators (keep list identity stable for SwiftUI diffing)

    func updateSchedule(_ id: String, _ mutate: (inout ScheduleEntry) -> Void) {
        guard let i = scheduleEntries.firstIndex(where: { $0.id == id }) else { return }
        mutate(&scheduleEntries[i])
    }
    func updateTodo(_ id: String, _ mutate: (inout OtherTodoItem) -> Void) {
        guard let i = otherTodoEntries.firstIndex(where: { $0.id == id }) else { return }
        mutate(&otherTodoEntries[i])
    }
    func updateGoal(_ id: String, _ mutate: (inout GoalEntry) -> Void) {
        guard let i = goalEntries.firstIndex(where: { $0.id == id }) else { return }
        mutate(&goalEntries[i])
    }

    // MARK: - Backup / restore (mirrors exportPrefsToJson / importPrefsFromJson)

    /// Export the whole store as a typed-value JSON snapshot (schema-compatible with the Android app).
    func exportJSON() -> String {
        let domain = UserDefaults.standard.persistentDomain(forName: AppStore.suiteName) ?? [:]
        var data: [String: Any] = [:]
        for (key, value) in domain {
            var entry: [String: Any] = [:]
            if let n = value as? NSNumber {
                if CFGetTypeID(n) == CFBooleanGetTypeID() {
                    entry = ["t": "b", "v": n.boolValue]
                } else if n.stringValue.contains(".") {
                    entry = ["t": "f", "v": n.doubleValue]
                } else if abs(n.int64Value) > Int64(Int32.max) {
                    entry = ["t": "l", "v": n.int64Value]
                } else {
                    entry = ["t": "i", "v": n.intValue]
                }
            } else if let s = value as? String {
                entry = ["t": "s", "v": s]
            } else if let arr = value as? [Any] {
                entry = ["t": "ss", "v": arr.map { "\($0)" }]
            }
            if !entry.isEmpty { data[key] = entry }
        }
        let root: [String: Any] = [
            "app": "Ascent", "schemaVersion": 1,
            "exportedAt": Int64(Date().timeIntervalSince1970 * 1000), "data": data
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted]),
              let str = String(data: jsonData, encoding: .utf8) else { return "{}" }
        return str
    }

    /// Restore from a backup snapshot. REPLACES all existing data, then reloads state. Returns success.
    @discardableResult
    func importJSON(_ json: String) -> Bool {
        guard let jsonData = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let data = root["data"] as? [String: Any] else { return false }
        var newDomain: [String: Any] = [:]
        for (key, raw) in data {
            guard let entry = raw as? [String: Any], let t = entry["t"] as? String else { continue }
            switch t {
            case "b": newDomain[key] = (entry["v"] as? Bool) ?? false
            case "i": newDomain[key] = JSON.int(entry, "v")
            case "l": newDomain[key] = JSON.long(entry, "v", 0)
            case "f": newDomain[key] = (entry["v"] as? NSNumber)?.doubleValue ?? 0
            case "s": newDomain[key] = entry["v"] as? String ?? ""
            case "ss": newDomain[key] = (entry["v"] as? [String]) ?? []
            default: break
            }
        }
        UserDefaults.standard.setPersistentDomain(newDomain, forName: AppStore.suiteName)
        load()
        return true
    }

    // Derived helpers.
    var rightNow: RightNowItem {
        pickRightNowItem(scheduleEntries: scheduleEntries, otherTodoEntries: otherTodoEntries)
    }
    func priorities(on date: CalDate) -> [ScheduleEntry] {
        scheduleEntries.filter { $0.date == date && $0.isTopPriority }
    }
}
