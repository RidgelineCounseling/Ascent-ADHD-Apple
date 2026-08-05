//
//  HomeView.swift
//  Ascent ADHD
//
//  The "Schedule" screen — Right Now card, scoreboard, week navigation, all-day chips, and the
//  day's timed schedule. The Android timeline is an absolute-positioned draggable hour grid; here
//  it's rendered as a clean chronological list (same data + interactions: tap to edit, tick to
//  complete, color blocks, times).
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var ui: UIState

    @State private var rightNowExpanded = false
    @State private var scoreboardExpanded = false
    @State private var showSpeedDial = false
    @State private var editorEntry: ScheduleEntry? = nil
    @State private var newEntryIsPriority = false
    @State private var presentEditor = false
    @State private var showFocusSetup = false
    @State private var showBrainDump = false
    @State private var showGoalEditor = false
    @State private var showQuickTodo = false
    @State private var quickTodoText = ""
    @State private var externalEvents: [ExternalEvent] = []
    @State private var presetStart: (Int, Int)? = nil

    private var selected: CalDate { ui.selectedDate }

    // Blocks shown on the timeline: app events, device-calendar events, and timed to-dos.
    private var timelineBlocks: [TimelineBlock] {
        var out: [TimelineBlock] = store.scheduleEntries
            .filter { $0.date == selected && !$0.isAllDay && $0.hasCustomTime }
            .map { e in
                TimelineBlock(id: e.id, task: e.task, notes: e.notes,
                              startMin: e.startMinutesOfDay, durationMins: e.durationMins,
                              color: e.blockColor, kind: .app, entry: e)
            }
        out += externalEvents.filter { !$0.isAllDay }.map { ext in
            TimelineBlock(id: "ext_\(ext.id)", task: ext.title, notes: "",
                          startMin: ext.startHour * 60 + ext.startMinute, durationMins: 60,
                          color: MistBlue.opacity(0.35), kind: .external, entry: nil)
        }
        out += store.otherTodoEntries
            .filter { !$0.isCompleted && $0.dueDate == selected && $0.dueTime != nil }
            .map { td in
                TimelineBlock(id: "todo_\(td.id)", task: td.text, notes: "",
                              startMin: (td.dueTime!.hour) * 60 + td.dueTime!.minute, durationMins: 15,
                              color: RidgelineBlue, kind: .todo, entry: nil)
            }
        return out
    }

    private var allDayEntries: [ScheduleEntry] {
        store.scheduleEntries.filter { $0.date == selected && $0.isAllDay }
    }
    private var unscheduledPriorities: [ScheduleEntry] {
        store.scheduleEntries.filter { $0.date == selected && !$0.isAllDay && !$0.hasCustomTime && $0.isTopPriority }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            SkyGray.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 6) {
                    rightNowCard
                    ScoreboardSection(
                        elevation: store.elevation,
                        todayCompletions: store.todayCompletions,
                        activityDates: store.activityDates,
                        isCondensed: !scoreboardExpanded,
                        onToggle: { scoreboardExpanded.toggle() }
                    )
                    WeekNavigator()
                    if !allDayEntries.isEmpty || !unscheduledPriorities.isEmpty {
                        allDayBar
                    }
                    ScheduleTimeline(
                        blocks: timelineBlocks,
                        isToday: selected == CalDate.today(),
                        onCreate: { hour, minute in
                            editorEntry = nil; newEntryIsPriority = false
                            presetStart = (hour, minute); presentEditor = true
                        },
                        onEdit: { entry in editEntry(entry) }
                    )
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }

            // Dim scrim behind the speed-dial (tap to dismiss).
            if showSpeedDial {
                PureBlack.opacity(0.25).ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeOut(duration: 0.2)) { showSpeedDial = false } }
                    .transition(.opacity)
            }

            fabArea
        }
        .onAppear(perform: loadExternalEvents)
        .onChange(of: selected) { _, _ in loadExternalEvents() }
        .onChange(of: store.showDeviceCalendar) { _, _ in loadExternalEvents() }
        .sheet(isPresented: $presentEditor) {
            TaskEditorSheet(entry: editorEntry, isPriority: newEntryIsPriority, ownerDate: selected, presetStart: presetStart)
        }
        .sheet(isPresented: $showFocusSetup) { FocusSetupSheet() }
        .sheet(isPresented: $showBrainDump) { BrainDumpSheet(date: selected) }
        .sheet(isPresented: $showGoalEditor) {
            GoalEditorSheet(goal: nil, type: "WEEKLY",
                            weekAnchor: selected.previousOrSameMonday, monthAnchor: nil)
        }
        .alert("Add a to-do", isPresented: $showQuickTodo) {
            TextField("What is it?", text: $quickTodoText)
            Button("Add") {
                let t = quickTodoText.trimmed
                if !t.isEmpty { store.otherTodoEntries.append(OtherTodoItem(text: t, date: selected)); store.recordActivity() }
                quickTodoText = ""
            }
            Button("Cancel", role: .cancel) { quickTodoText = "" }
        }
    }

    // MARK: Speed-dial FAB (ported from the Android add-sheet)

    private func fire(_ action: @escaping () -> Void) {
        withAnimation(.easeOut(duration: 0.2)) { showSpeedDial = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: action)
    }

    private func speedDialPill(_ icon: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(PureWhite).frame(width: 22)
            Text(label).font(AscentFont.titleMedium).foregroundColor(PureWhite)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(Capsule().fill(RidgelineBlue))
        .shadow(color: PureBlack.opacity(0.15), radius: 4, y: 2)
        .contentShape(Capsule())
        .onTapGesture { fire(action) }
    }

    private var fabArea: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if showSpeedDial {
                speedDialPill("calendar.badge.plus", "Schedule an event") {
                    editorEntry = nil; newEntryIsPriority = false; presentEditor = true
                }
                speedDialPill("brain.head.profile", "Brain dump") { showBrainDump = true }
                speedDialPill("doc.text", "Add a to-do") { showQuickTodo = true }
                speedDialPill("timer", "Focus session") { showFocusSetup = true }
                speedDialPill("flag", "New goal") { showGoalEditor = true }
            }

            // Today-return chip (only when off today).
            if !showSpeedDial && selected != CalDate.today() {
                Button { ui.selectedDate = .today() } label: {
                    Text("\(CalDate.today().dayOfMonth)")
                        .font(AscentFont.titleMedium).foregroundColor(PureWhite)
                        .frame(width: 44, height: 44).background(Circle().fill(RidgelineBlue))
                }
            }

            // The FAB: + rotates to × while the dial is open.
            Button { withAnimation(.easeOut(duration: 0.2)) { showSpeedDial.toggle() } } label: {
                Image(systemName: "plus").font(.system(size: 26, weight: .semibold)).foregroundColor(PureWhite)
                    .rotationEffect(.degrees(showSpeedDial ? 45 : 0))
                    .frame(width: 54, height: 54).background(Circle().fill(RidgelineBlue))
                    .shadow(color: PureBlack.opacity(0.2), radius: 6, y: 3)
            }
        }
        .padding(.trailing, 20).padding(.bottom, 24)
    }

    // MARK: Right Now

    @ViewBuilder private var rightNowCard: some View {
        let rn = store.rightNow
        let eyebrow: String = {
            switch rn {
            case .priority: return "TOP PRIORITY"
            case .todo(let t): return t.date.isBefore(CalDate.today()) ? "CARRIED OVER" : "NEXT TO-DO"
            case .event: return "ON YOUR SCHEDULE"
            case .allClear: return "ALL CLEAR"
            }
        }()
        let subLine: String = {
            switch rn {
            case .event(_, let s): return s
            case .priority(let e): return e.hasCustomTime ? formatTimeLabel(e.startHour, e.startMinute) : ""
            case .todo(let t):
                let daysOver = CalDate.today().epochDay - t.date.epochDay
                if daysOver <= 0 { return "" }
                return daysOver == 1 ? "From yesterday" : "From \(daysOver) days ago"
            case .allClear: return ""
            }
        }()

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(eyebrow).font(AscentFont.labelSmall).foregroundColor(PureWhite)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Capsule().fill(PureWhite.opacity(0.18)))
                Text({ if case .allClear = rn { return "🎉 Deck cleared!" } else { return rn.task } }())
                    .font(AscentFont.titleMedium).foregroundColor(PureWhite).lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if case .allClear = rn {} else {
                    Image(systemName: rightNowExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16)).foregroundColor(PureWhite.opacity(0.9))
                }
            }
            if rightNowExpanded, case .allClear = rn {} else if rightNowExpanded {
                let pieces = [subLine, rn.reward.isEmpty ? "" : "🎁 \(rn.reward)"].filter { !$0.isEmpty }
                if !pieces.isEmpty {
                    Text(pieces.joined(separator: "  ·  "))
                        .font(AscentFont.labelSmall).foregroundColor(PureWhite.opacity(0.85)).lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, rightNowExpanded ? 10 : 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(RidgelineBlue))
        .onTapGesture { withAnimation { rightNowExpanded.toggle() } }
        .padding(.vertical, 4)
    }

    // MARK: All-day / unscheduled chips

    private var allDayBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(unscheduledPriorities) { p in
                    chip(icon: p.isCompleted ? "checkmark.circle.fill" : "circle",
                         text: p.task, bg: RidgelineBlue, fg: PureWhite,
                         strike: p.isCompleted) { editEntry(p) }
                }
                ForEach(allDayEntries) { e in
                    chip(icon: "pin", text: e.task, bg: e.blockColor, fg: MidnightSlate,
                         strike: e.isCompleted) { editEntry(e) }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(icon: String, text: String, bg: Color, fg: Color, strike: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 12)).foregroundColor(fg)
            Text(text).font(.system(size: 12, weight: .bold)).foregroundColor(fg).strikethrough(strike)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(bg))
        .onTapGesture(perform: action)
    }

    private func loadExternalEvents() {
        guard store.showDeviceCalendar else { externalEvents = []; return }
        if CalendarService.shared.isAuthorized {
            externalEvents = CalendarService.shared.events(on: selected)
        } else {
            CalendarService.shared.requestAccess { granted in
                if granted { externalEvents = CalendarService.shared.events(on: selected) }
            }
        }
    }

    // MARK: Actions

    private func editEntry(_ entry: ScheduleEntry) {
        presetStart = nil
        editorEntry = entry; newEntryIsPriority = entry.isTopPriority; presentEditor = true
    }
}
