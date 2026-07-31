//
//  Models.swift
//  Ascent ADHD
//
//  Core data models ported from MainActivity.kt. Each type carries a toJSON()/init(json:) pair that
//  mirrors the Android org.json (de)serialization key-for-key, so the persisted store — and any
//  exported backup — round-trips identically across platforms.
//

import SwiftUI
import Foundation

// MARK: - JSON read helpers  (mirror the JSONObject.opt* extension helpers)

enum JSON {
    static func str(_ o: [String: Any], _ k: String, _ def: String = "") -> String {
        (o[k] as? String) ?? def
    }
    static func optStr(_ o: [String: Any], _ k: String) -> String? {
        guard let v = o[k] as? String, !v.isEmpty else { return nil }
        return v
    }
    static func bool(_ o: [String: Any], _ k: String, _ def: Bool = false) -> Bool {
        (o[k] as? Bool) ?? def
    }
    static func int(_ o: [String: Any], _ k: String, _ def: Int = 0) -> Int {
        if let i = o[k] as? Int { return i }
        if let n = o[k] as? NSNumber { return n.intValue }
        return def
    }
    static func long(_ o: [String: Any], _ k: String, _ def: Int64) -> Int64 {
        if let n = o[k] as? NSNumber { return n.int64Value }
        return def
    }
    static func optLong(_ o: [String: Any], _ k: String) -> Int64? {
        if o[k] == nil || o[k] is NSNull { return nil }
        if let n = o[k] as? NSNumber { return n.int64Value }
        return nil
    }
}

private func nowMillis() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000) }

// Color <-> packed int, matching Android's Color.toArgb() (a signed 32-bit Int).
private func colorToInt(_ c: Color) -> Int { Int(Int32(bitPattern: c.argb)) }
private func intToColor(_ o: [String: Any], _ k: String) -> Color {
    let raw = JSON.int(o, k, colorToInt(PureWhite))
    return Color(argb: UInt32(bitPattern: Int32(truncatingIfNeeded: raw)))
}

// MARK: - TodoSubtask

struct TodoSubtask: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var text: String
    var isCompleted: Bool = false
    var dueDate: CalDate? = nil
    var dueTime: CalTime? = nil
    var details: String = ""

    func toJSON() -> [String: Any] {
        var o: [String: Any] = ["id": id, "text": text, "isCompleted": isCompleted, "details": details]
        if let d = dueDate { o["dueDate"] = d.iso }
        if let t = dueTime { o["dueTime"] = t.iso }
        return o
    }
    static func from(_ o: [String: Any]) -> TodoSubtask {
        TodoSubtask(
            id: JSON.optStr(o, "id") ?? UUID().uuidString,
            text: JSON.str(o, "text"),
            isCompleted: JSON.bool(o, "isCompleted"),
            dueDate: CalDate.parse(JSON.optStr(o, "dueDate")),
            dueTime: CalTime.parse(JSON.optStr(o, "dueTime")),
            details: JSON.str(o, "details")
        )
    }
}

func subtasksToJSON(_ subtasks: [TodoSubtask]) -> [[String: Any]] { subtasks.map { $0.toJSON() } }
func subtasksFromJSON(_ arr: [[String: Any]]?) -> [TodoSubtask] { (arr ?? []).map { TodoSubtask.from($0) } }

// MARK: - ScheduleEntry  (a schedule event / priority)

struct ScheduleEntry: Identifiable, Hashable {
    var defaultSlotLabel: String
    var task: String
    var isTopPriority: Bool
    var notes: String = ""
    var blockColor: Color = PureWhite
    var isCompleted: Bool = false
    var startHour: Int = 0
    var startMinute: Int = 0
    var durationMins: Int = 60
    var hasCustomTime: Bool = false
    var date: CalDate = .today()
    var reward: String = ""
    var isAllDay: Bool = false
    var reminderEpochMillis: Int64? = nil
    var reminderNightBefore: Bool = false
    var reminderMorningOf: Bool = false
    var triggerCue: String = ""
    var subtasks: [TodoSubtask] = []
    var id: String = UUID().uuidString

    var startMinutesOfDay: Int { startHour * 60 + startMinute }

    func toJSON() -> [String: Any] {
        var o: [String: Any] = [
            "id": id, "defaultSlotLabel": defaultSlotLabel, "task": task,
            "isTopPriority": isTopPriority, "notes": notes,
            "isCompleted": isCompleted, "startHour": startHour, "startMinute": startMinute,
            "durationMins": durationMins, "hasCustomTime": hasCustomTime, "date": date.iso,
            "reward": reward, "isAllDay": isAllDay, "reminderNightBefore": reminderNightBefore,
            "reminderMorningOf": reminderMorningOf, "triggerCue": triggerCue,
            "blockColor": colorToInt(blockColor),
            "subtasks": subtasksToJSON(subtasks)
        ]
        if let r = reminderEpochMillis { o["reminderEpochMillis"] = NSNumber(value: r) }
        return o
    }
    static func from(_ o: [String: Any]) -> ScheduleEntry {
        ScheduleEntry(
            defaultSlotLabel: JSON.str(o, "defaultSlotLabel"),
            task: JSON.str(o, "task"),
            isTopPriority: JSON.bool(o, "isTopPriority"),
            notes: JSON.str(o, "notes"),
            blockColor: intToColor(o, "blockColor"),
            isCompleted: JSON.bool(o, "isCompleted"),
            startHour: JSON.int(o, "startHour"),
            startMinute: JSON.int(o, "startMinute"),
            durationMins: JSON.int(o, "durationMins", 60),
            hasCustomTime: JSON.bool(o, "hasCustomTime"),
            date: CalDate.parse(JSON.optStr(o, "date")) ?? .today(),
            reward: JSON.str(o, "reward"),
            isAllDay: JSON.bool(o, "isAllDay"),
            reminderEpochMillis: JSON.optLong(o, "reminderEpochMillis"),
            reminderNightBefore: JSON.bool(o, "reminderNightBefore"),
            reminderMorningOf: JSON.bool(o, "reminderMorningOf"),
            triggerCue: JSON.str(o, "triggerCue"),
            subtasks: subtasksFromJSON(o["subtasks"] as? [[String: Any]]),
            id: JSON.optStr(o, "id") ?? UUID().uuidString
        )
    }
}

// MARK: - OtherTodoItem  (a to-do on the Lists screen)

struct OtherTodoItem: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var text: String
    var isCompleted: Bool = false
    var date: CalDate
    var completedDate: CalDate? = nil
    var reward: String = ""
    var reminderEpochMillis: Int64? = nil
    var reminderNightBefore: Bool = false
    var reminderMorningOf: Bool = false
    var triggerCue: String = ""
    var subtasks: [TodoSubtask] = []
    var fromBrainDump: Bool = false
    var dueDate: CalDate? = nil
    var dueTime: CalTime? = nil
    var notes: String = ""
    var blockColor: Color = PureWhite

    func toJSON() -> [String: Any] {
        var o: [String: Any] = [
            "id": id, "text": text, "isCompleted": isCompleted, "date": date.iso,
            "reward": reward, "reminderNightBefore": reminderNightBefore,
            "reminderMorningOf": reminderMorningOf, "triggerCue": triggerCue,
            "fromBrainDump": fromBrainDump, "notes": notes,
            "blockColor": colorToInt(blockColor),
            "subtasks": subtasksToJSON(subtasks)
        ]
        if let c = completedDate { o["completedDate"] = c.iso }
        if let r = reminderEpochMillis { o["reminderEpochMillis"] = NSNumber(value: r) }
        if let d = dueDate { o["dueDate"] = d.iso }
        if let t = dueTime { o["dueTime"] = t.iso }
        return o
    }
    static func from(_ o: [String: Any]) -> OtherTodoItem {
        OtherTodoItem(
            id: JSON.optStr(o, "id") ?? UUID().uuidString,
            text: JSON.str(o, "text"),
            isCompleted: JSON.bool(o, "isCompleted"),
            date: CalDate.parse(JSON.optStr(o, "date")) ?? .today(),
            completedDate: CalDate.parse(JSON.optStr(o, "completedDate")),
            reward: JSON.str(o, "reward"),
            reminderEpochMillis: JSON.optLong(o, "reminderEpochMillis"),
            reminderNightBefore: JSON.bool(o, "reminderNightBefore"),
            reminderMorningOf: JSON.bool(o, "reminderMorningOf"),
            triggerCue: JSON.str(o, "triggerCue"),
            subtasks: subtasksFromJSON(o["subtasks"] as? [[String: Any]]),
            fromBrainDump: JSON.bool(o, "fromBrainDump"),
            dueDate: CalDate.parse(JSON.optStr(o, "dueDate")),
            dueTime: CalTime.parse(JSON.optStr(o, "dueTime")),
            notes: JSON.str(o, "notes"),
            blockColor: intToColor(o, "blockColor")
        )
    }
}

// MARK: - InsightLog  (retired feature; still deserialized for backups)

struct InsightLog: Identifiable, Hashable {
    var id: Int64 = nowMillis()
    var behavior: String
    var trigger: String
    var timeOfDay: String
    var date: CalDate = .today()

    func toJSON() -> [String: Any] {
        ["id": NSNumber(value: id), "behavior": behavior, "trigger": trigger, "timeOfDay": timeOfDay, "date": date.iso]
    }
    static func from(_ o: [String: Any]) -> InsightLog {
        InsightLog(
            id: JSON.long(o, "id", nowMillis()),
            behavior: JSON.str(o, "behavior"),
            trigger: JSON.str(o, "trigger"),
            timeOfDay: JSON.str(o, "timeOfDay"),
            date: CalDate.parse(JSON.optStr(o, "date")) ?? .today()
        )
    }
}

// MARK: - ReflectionEntry  (daily guided reflection answer)

struct ReflectionEntry: Identifiable, Hashable {
    var id: Int64 = nowMillis()
    var date: CalDate = .today()
    var prompt: String
    var response: String

    func toJSON() -> [String: Any] {
        ["id": NSNumber(value: id), "date": date.iso, "prompt": prompt, "response": response]
    }
    static func from(_ o: [String: Any]) -> ReflectionEntry {
        ReflectionEntry(
            id: JSON.long(o, "id", nowMillis()),
            date: CalDate.parse(JSON.optStr(o, "date")) ?? .today(),
            prompt: JSON.str(o, "prompt"),
            response: JSON.str(o, "response")
        )
    }
}

struct ReflectionPrompt: Hashable {
    var text: String
    var linkedNoteId: String? = nil
}

// MARK: - GoalStep / GoalEntry

struct GoalStep: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var text: String
    var deadlineDate: CalDate? = nil
    var isCompleted: Bool = false

    func toJSON() -> [String: Any] {
        var o: [String: Any] = ["id": id, "text": text, "isCompleted": isCompleted]
        if let d = deadlineDate { o["deadlineDate"] = d.iso }
        return o
    }
    static func from(_ o: [String: Any]) -> GoalStep {
        GoalStep(
            id: JSON.optStr(o, "id") ?? UUID().uuidString,
            text: JSON.str(o, "text"),
            deadlineDate: CalDate.parse(JSON.optStr(o, "deadlineDate")),
            isCompleted: JSON.bool(o, "isCompleted")
        )
    }
}

struct GoalEntry: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var steps: [GoalStep] = []
    var deadlineDate: CalDate? = nil
    var reward: String = ""
    var isCompleted: Bool = false
    var weekAnchor: CalDate? = nil
    var monthAnchor: CalMonth? = nil
    var type: String = "WEEKLY"   // "WEEKLY" | "MONTHLY"
    var futureVision: String = ""

    func toJSON() -> [String: Any] {
        var o: [String: Any] = [
            "id": id, "title": title, "steps": steps.map { $0.toJSON() },
            "reward": reward, "isCompleted": isCompleted, "type": type, "futureVision": futureVision
        ]
        if let d = deadlineDate { o["deadlineDate"] = d.iso }
        if let w = weekAnchor { o["weekAnchor"] = w.iso }
        if let m = monthAnchor { o["monthAnchor"] = m.iso }
        return o
    }
    static func from(_ o: [String: Any]) -> GoalEntry {
        let stepsArr = (o["steps"] as? [[String: Any]]) ?? []
        return GoalEntry(
            id: JSON.optStr(o, "id") ?? UUID().uuidString,
            title: JSON.str(o, "title"),
            steps: stepsArr.map { GoalStep.from($0) },
            deadlineDate: CalDate.parse(JSON.optStr(o, "deadlineDate")),
            reward: JSON.str(o, "reward"),
            isCompleted: JSON.bool(o, "isCompleted"),
            weekAnchor: CalDate.parse(JSON.optStr(o, "weekAnchor")),
            monthAnchor: CalMonth.parse(JSON.optStr(o, "monthAnchor")),
            type: JSON.str(o, "type", "WEEKLY"),
            futureVision: JSON.str(o, "futureVision")
        )
    }
}

// MARK: - WizardItem / RewardBank / FocusSession

struct WizardItem: Identifiable, Hashable {
    var text: String
    var id: Int64 = nowMillis()
}

struct RewardBank: Hashable {
    var small: [String]
    var medium: [String]
    static let empty = RewardBank(small: [], medium: [])
}

struct FocusSession: Hashable {
    var taskLabel: String
    var workMinutes: Int
    var phase: String = FOCUS_PHASE_WORK
    var secondsLeft: Int
    var chunksCompleted: Int = 0
    var isPaused: Bool = false

    init(taskLabel: String, workMinutes: Int, phase: String = FOCUS_PHASE_WORK,
         secondsLeft: Int? = nil, chunksCompleted: Int = 0, isPaused: Bool = false) {
        self.taskLabel = taskLabel
        self.workMinutes = workMinutes
        self.phase = phase
        self.secondsLeft = secondsLeft ?? workMinutes * 60
        self.chunksCompleted = chunksCompleted
        self.isPaused = isPaused
    }
}

let FOCUS_PHASE_WORK = "WORK"
let FOCUS_PHASE_BREAK = "BREAK"
let FOCUS_BREAK_MINUTES = 5

// MARK: - CustomNotification (in-app banner)

struct CustomNotificationData: Identifiable {
    let id = UUID()
    var title: String
    var message: String
    var bgColor: Color
    var icon: String
}

// MARK: - Elevation & Milestones

let ELEVATION_TODO = 10
let ELEVATION_PRIORITY = 20
let ELEVATION_STEP = 30

struct Milestone: Hashable {
    let threshold: Int
    let name: String
}

let MILESTONE_LADDER: [Milestone] = [
    Milestone(threshold: 0, name: "Trailhead"),
    Milestone(threshold: 50, name: "Base Camp"),
    Milestone(threshold: 120, name: "Foothills"),
    Milestone(threshold: 220, name: "Tree Line"),
    Milestone(threshold: 360, name: "The Ridge"),
    Milestone(threshold: 560, name: "Alpine Zone"),
    Milestone(threshold: 840, name: "High Camp"),
    Milestone(threshold: 1220, name: "The Summit"),
    Milestone(threshold: 1720, name: "Skyward"),
    Milestone(threshold: 2360, name: "Cloudbreaker"),
    Milestone(threshold: 3160, name: "Stratosphere")
]

/// The highest milestone whose threshold the elevation has reached or passed.
func currentMilestone(_ elevation: Int) -> Milestone {
    MILESTONE_LADDER.last { elevation >= $0.threshold } ?? MILESTONE_LADDER[0]
}
/// The next milestone above the current elevation, or nil if past the top of the named ladder.
func nextMilestone(_ elevation: Int) -> Milestone? {
    MILESTONE_LADDER.first { elevation < $0.threshold }
}
/// Today's climb-intensity tier, 0–3, based on completions today.
func todaysClimbTier(_ completionsToday: Int) -> Int { min(max(completionsToday, 0), 3) }

// MARK: - Right Now selection

enum RightNowItem {
    case priority(ScheduleEntry)
    case todo(OtherTodoItem)
    case event(ScheduleEntry, statusLabel: String)
    case allClear

    var task: String {
        switch self {
        case .priority(let e): return e.task
        case .todo(let t): return t.text
        case .event(let e, _): return e.task
        case .allClear: return ""
        }
    }
    var reward: String {
        switch self {
        case .priority(let e): return e.reward
        case .todo(let t): return t.reward
        case .event(let e, _): return e.reward
        case .allClear: return ""
        }
    }
}

/// Pick what the Right Now card should show (ported from pickRightNowItem).
func pickRightNowItem(scheduleEntries: [ScheduleEntry], otherTodoEntries: [OtherTodoItem], now: Date = Date()) -> RightNowItem {
    let today = CalDate(now)
    let comps = Calendar.current.dateComponents([.hour, .minute], from: now)
    let nowMins = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

    let todaysEntries = scheduleEntries.filter { $0.date == today && !$0.isCompleted && !$0.isAllDay }

    // Tier 1: uncompleted priorities, soonest start first.
    if let nextPriority = todaysEntries.filter({ $0.isTopPriority }).min(by: { $0.startMinutesOfDay < $1.startMinutesOfDay }) {
        return .priority(nextPriority)
    }

    // Tier 2: uncompleted to-dos due today or carried over, oldest first.
    if let nextTodo = otherTodoEntries.filter({ !$0.isCompleted && !$0.date.isAfter(today) }).min(by: { $0.date < $1.date }) {
        return .todo(nextTodo)
    }

    // Tier 3: no tasks left — surface the next non-priority event for context.
    let nonPriority = todaysEntries.filter { !$0.isTopPriority }
    let inProgress = nonPriority
        .map { ($0, $0.startMinutesOfDay) }
        .filter { (e, startMins) in startMins <= nowMins && nowMins < startMins + e.durationMins }
        .min { (nowMins - $0.1) < (nowMins - $1.1) }
    if let (e, startMins) = inProgress {
        let minutesUntilEnd = (startMins + e.durationMins) - nowMins
        return .event(e, statusLabel: "Happening now · \(minutesUntilEnd) min left")
    }
    let upcoming = nonPriority
        .map { ($0, $0.startMinutesOfDay) }
        .filter { $0.1 > nowMins }
        .min { $0.1 < $1.1 }
    if let (e, _) = upcoming {
        return .event(e, statusLabel: "Up next · \(formatTimeLabel(e.startHour, e.startMinute))")
    }

    // Tier 4: nothing left.
    return .allClear
}

// MARK: - Time formatting

func formatTimeLabel(_ hour: Int, _ minute: Int) -> String {
    let period = hour < 12 ? "AM" : "PM"
    var h = hour % 12
    if h == 0 { h = 12 }
    return String(format: "%d:%02d %@", h, minute, period)
}

// MARK: - Reflection prompts

let REFLECTION_PROMPTS: [ReflectionPrompt] = [
    ReflectionPrompt(text: "What made starting something hard today — and did anything help?"),
    ReflectionPrompt(text: "What's one thing that went better than you expected today?"),
    ReflectionPrompt(text: "When did you feel most focused or in-flow today?"),
    ReflectionPrompt(text: "What's one small win worth noticing from today?"),
    ReflectionPrompt(text: "Did you get to be kind to yourself when something slipped today?", linkedNoteId: "tn_self_compassion"),
    ReflectionPrompt(text: "Did breaking something into smaller pieces help you start today?", linkedNoteId: "tn_delay_aversion"),
    ReflectionPrompt(text: "Did having someone nearby — even virtually — help you get going?", linkedNoteId: "tn_body_doubling"),
    ReflectionPrompt(text: "Did getting something out of your head and onto paper help today?", linkedNoteId: "tn_working_memory"),
    ReflectionPrompt(text: "Did a reward, big or small, help you follow through on anything?", linkedNoteId: "tn_chosen_rewards"),
    ReflectionPrompt(text: "Where did time slip away from you today — what were you doing?", linkedNoteId: "tn_time_blindness"),
    ReflectionPrompt(text: "What's one thing you're carrying into tomorrow?"),
    ReflectionPrompt(text: "What drained your energy today, and what restored it?"),
    ReflectionPrompt(text: "Did a strong feeling show up today? What was underneath it?", linkedNoteId: "tn_rsd"),
    ReflectionPrompt(text: "What would make tomorrow one percent easier?"),
    ReflectionPrompt(text: "Did a warning before switching tasks help you today?", linkedNoteId: "tn_task_switching")
]

func reflectionPromptForDate(_ date: CalDate) -> ReflectionPrompt {
    let idx = Int(((date.epochDay % Int64(REFLECTION_PROMPTS.count)) + Int64(REFLECTION_PROMPTS.count)) % Int64(REFLECTION_PROMPTS.count))
    return REFLECTION_PROMPTS[idx]
}

// MARK: - Default tracking behaviors (first-launch picker)

let DEFAULT_BEHAVIORS: [String] = [
    "📱 Social Media", "🍩 Snacks/Sugar", "🎮 Video Games", "📺 Binge Watching",
    "🛍️ Impulse Buying", "🌀 Doomscrolling", "☕ Caffeine", "🐢 Procrastinating",
    "🍽️ Skipping Meals", "🌙 Sleep Avoidance", "📲 Phone Pickups", "💅 Nail Biting"
]

// MARK: - Why-chip explanation copy

let WHY_TRIGGER_CUE_TITLE = "Why \"When I…\"?"
let WHY_TRIGGER_CUE_BODY = "Linking a task to something you already do — \"when I finish my coffee, I'll…\" — gives your brain a concrete cue to start. ADHD makes task initiation hard, and an if-then plan like this takes the decision out of the moment, so starting feels more automatic."
let WHY_FUTURE_VISION_TITLE = "Why picture finishing?"
let WHY_FUTURE_VISION_BODY = "ADHD brains tend to discount future rewards steeply — a payoff that's far away feels less real now. Vividly imagining the moment you finish (where you are, how it feels) makes that future reward feel closer and more motivating today."
let WHY_REWARD_TITLE = "Why a reward?"
let WHY_REWARD_BODY = "Reward works better than pressure for ADHD motivation, and a reward you chose yourself works best of all. Picking something small and immediate gives your brain a clear, near-term reason to follow through."
