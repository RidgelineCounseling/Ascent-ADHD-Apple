//
//  Editors.swift
//  Ascent ADHD
//
//  Shared modal editors: the task composer (TaskComposerDialog / TaskDetailDialog), the goal
//  builder (goal wizard), and the Trail Note reader. Presented as sheets from the screens.
//

import SwiftUI

// MARK: - Task editor (create/edit a schedule event or priority)

struct TaskEditorSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let entry: ScheduleEntry?          // nil = create new
    let isPriority: Bool
    let ownerDate: CalDate
    var presetStart: (Int, Int)? = nil   // (hour, minute) for a new event created from the timeline

    @State private var task = ""
    @State private var notes = ""
    @State private var priority = false
    @State private var allDay = false
    @State private var hasCustomTime = true
    @State private var startTime = Date()
    @State private var durationMins = 60
    @State private var reward = ""
    @State private var triggerCue = ""
    @State private var selectedColor = PureWhite
    @State private var subtasks: [TodoSubtask] = []
    @State private var newSubtask = ""
    @State private var reminderNightBefore = false
    @State private var reminderMorningOf = false
    @State private var showColorPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What is it?", text: $task)
                    Toggle("Top priority", isOn: $priority)
                    Toggle("All-day", isOn: $allDay)
                    if !allDay {
                        Toggle("Set a time", isOn: $hasCustomTime)
                        if hasCustomTime {
                            DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                            Stepper("Duration: \(durationMins) min", value: $durationMins, in: 5...600, step: 5)
                        }
                    }
                }
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(EventColors.enumerated()), id: \.offset) { _, color in
                                let isSel = color.argb == selectedColor.argb
                                Circle().fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(isSel ? RidgelineBlue : BorderGray, lineWidth: isSel ? 3 : 1))
                                    .onTapGesture { selectedColor = color }
                            }
                            // Custom-color swatch (opens the HSV picker).
                            let isCustom = !EventColors.contains { $0.argb == selectedColor.argb }
                            ZStack {
                                Circle().fill(isCustom ? selectedColor : Color.clear)
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(isCustom ? RidgelineBlue : BorderGray, lineWidth: isCustom ? 3 : 1))
                                Image(systemName: "eyedropper").font(.system(size: 13))
                                    .foregroundColor(isCustom ? PureWhite : RidgelineBlue)
                            }
                            .onTapGesture { showColorPicker = true }
                        }.padding(.vertical, 4)
                    }
                }
                Section {
                    RewardChipsRow(bank: store.rewardBank) { reward = $0 }
                    TextField("🎁 Reward (optional)", text: $reward)
                } header: {
                    HStack { Text("Reward"); WhyChip(title: WHY_REWARD_TITLE, explanation: WHY_REWARD_BODY) }
                }
                Section {
                    TextField("When I… (starter cue)", text: $triggerCue)
                } header: {
                    HStack { Text("Starter cue"); WhyChip(title: WHY_TRIGGER_CUE_TITLE, explanation: WHY_TRIGGER_CUE_BODY) }
                }
                Section("Reminders") {
                    Toggle("Night before (8 PM)", isOn: $reminderNightBefore)
                    Toggle("Morning of (9 AM)", isOn: $reminderMorningOf)
                }
                Section("Subtasks") {
                    ForEach($subtasks) { $st in
                        HStack {
                            Image(systemName: st.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(st.isCompleted ? SuccessGreen : MistBlue)
                                .onTapGesture { st.isCompleted.toggle() }
                            Text(st.text)
                            Spacer()
                            Button { subtasks.removeAll { $0.id == st.id } } label: {
                                Image(systemName: "xmark").foregroundColor(.gray)
                            }
                        }
                    }
                    HStack {
                        TextField("Add a subtask…", text: $newSubtask)
                        Button {
                            let t = newSubtask.trimmed
                            if !t.isEmpty { subtasks.append(TodoSubtask(text: t)); newSubtask = "" }
                        } label: { Image(systemName: "plus.circle.fill").foregroundColor(RidgelineBlue) }
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...5)
                }
                if entry != nil {
                    Section {
                        Button("Delete", role: .destructive) { deleteEntry() }
                    }
                }
            }
            .navigationTitle(entry == nil ? (isPriority ? "New priority" : "New event") : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(task.trimmed.isEmpty) }
            }
            .sheet(isPresented: $showColorPicker) {
                CustomColorPicker(initial: selectedColor) { selectedColor = $0 }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let e = entry {
            task = e.task; notes = e.notes; priority = e.isTopPriority; allDay = e.isAllDay
            hasCustomTime = e.hasCustomTime; durationMins = e.durationMins; reward = e.reward
            triggerCue = e.triggerCue; selectedColor = e.blockColor; subtasks = e.subtasks
            reminderNightBefore = e.reminderNightBefore; reminderMorningOf = e.reminderMorningOf
            var comps = DateComponents(); comps.hour = e.startHour; comps.minute = e.startMinute
            startTime = Calendar.current.date(from: comps) ?? Date()
        } else {
            priority = isPriority
            if let (h, m) = presetStart {
                var comps = DateComponents(); comps.hour = h; comps.minute = m
                startTime = Calendar.current.date(from: comps) ?? Date()
            }
        }
    }

    private func save() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: startTime)
        let hour = comps.hour ?? 9, minute = comps.minute ?? 0
        let id: String
        if let e = entry {
            id = e.id
            store.updateSchedule(e.id) {
                $0.task = task.trimmed; $0.notes = notes; $0.isTopPriority = priority; $0.isAllDay = allDay
                $0.hasCustomTime = !allDay && hasCustomTime; $0.startHour = hour; $0.startMinute = minute
                $0.durationMins = durationMins; $0.reward = reward; $0.triggerCue = triggerCue
                $0.blockColor = selectedColor; $0.subtasks = subtasks
                $0.reminderNightBefore = reminderNightBefore; $0.reminderMorningOf = reminderMorningOf
            }
        } else {
            let new = ScheduleEntry(
                defaultSlotLabel: "", task: task.trimmed, isTopPriority: priority, notes: notes,
                blockColor: selectedColor, startHour: hour, startMinute: minute, durationMins: durationMins,
                hasCustomTime: !allDay && hasCustomTime, date: ownerDate, reward: reward,
                isAllDay: allDay, reminderNightBefore: reminderNightBefore, reminderMorningOf: reminderMorningOf,
                triggerCue: triggerCue, subtasks: subtasks)
            id = new.id
            store.scheduleEntries.append(new)
            store.recordActivity()
        }
        scheduleReminders(for: id)
        dismiss()
    }

    private func scheduleReminders(for id: String) {
        Reminders.cancelAllReminders(itemId: id)
        if reminderNightBefore, let d = nightBeforeDate(ownerDate) {
            Reminders.scheduleReminder(itemId: id, slot: "night", title: "Tomorrow: \(task.trimmed)", body: "A heads-up for tomorrow.", at: d)
        }
        if reminderMorningOf, let d = morningOfDate(ownerDate) {
            Reminders.scheduleReminder(itemId: id, slot: "morning", title: "Today: \(task.trimmed)", body: "On your plan for today.", at: d)
        }
    }

    private func deleteEntry() {
        if let e = entry { Reminders.cancelAllReminders(itemId: e.id); store.scheduleEntries.removeAll { $0.id == e.id } }
        dismiss()
    }
}

// MARK: - Goal editor

struct GoalEditorSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let goal: GoalEntry?         // nil = create
    let type: String             // "WEEKLY" | "MONTHLY"
    let weekAnchor: CalDate?
    let monthAnchor: CalMonth?

    @State private var title = ""
    @State private var reward = ""
    @State private var vision = ""
    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var steps: [GoalStep] = []
    @State private var newStep = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(type == "WEEKLY" ? "Weekly goal" : "Monthly goal", text: $title)
                    Toggle("Deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Due", selection: $deadline, displayedComponents: .date)
                    }
                }
                Section {
                    RewardChipsRow(bank: store.rewardBank) { reward = $0 }
                    TextField("🎁 Reward (optional)", text: $reward)
                } header: {
                    HStack { Text("Reward"); WhyChip(title: WHY_REWARD_TITLE, explanation: WHY_REWARD_BODY) }
                }
                Section {
                    TextField("Picture finishing…", text: $vision, axis: .vertical).lineLimit(2...4)
                } header: {
                    HStack { Text("Future vision"); WhyChip(title: WHY_FUTURE_VISION_TITLE, explanation: WHY_FUTURE_VISION_BODY) }
                }
                Section("Steps") {
                    ForEach(steps) { step in
                        HStack {
                            Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(step.isCompleted ? SuccessGreen : MistBlue)
                            Text(step.text)
                            Spacer()
                            Button { steps.removeAll { $0.id == step.id } } label: {
                                Image(systemName: "xmark").foregroundColor(.gray)
                            }
                        }
                    }
                    HStack {
                        TextField("Add a step…", text: $newStep)
                        Button {
                            let t = newStep.trimmed
                            if !t.isEmpty { steps.append(GoalStep(text: t)); newStep = "" }
                        } label: { Image(systemName: "plus.circle.fill").foregroundColor(RidgelineBlue) }
                    }
                }
                if goal != nil {
                    Section { Button("Delete", role: .destructive) { deleteGoal() } }
                }
            }
            .navigationTitle(goal == nil ? "New goal" : "Edit goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(title.trimmed.isEmpty) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let g = goal {
            title = g.title; reward = g.reward; vision = g.futureVision; steps = g.steps
            if let d = g.deadlineDate {
                hasDeadline = true
                deadline = Calendar.current.date(from: DateComponents(year: d.year, month: d.month, day: d.day)) ?? Date()
            }
        }
    }

    private func save() {
        let deadlineCal = hasDeadline ? CalDate(deadline) : nil
        if let g = goal {
            store.updateGoal(g.id) {
                $0.title = title.trimmed; $0.reward = reward; $0.futureVision = vision
                $0.steps = steps; $0.deadlineDate = deadlineCal
            }
        } else {
            let new = GoalEntry(title: title.trimmed, steps: steps, deadlineDate: deadlineCal, reward: reward,
                                weekAnchor: type == "WEEKLY" ? weekAnchor : nil,
                                monthAnchor: type == "MONTHLY" ? monthAnchor : nil,
                                type: type, futureVision: vision)
            store.goalEntries.append(new)
            store.recordActivity()
        }
        dismiss()
    }

    private func deleteGoal() {
        if let g = goal { store.goalEntries.removeAll { $0.id == g.id } }
        dismiss()
    }
}

// MARK: - Trail Note reader

struct TrailNoteReader: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let note: TrailNote
    @State private var picked: Int? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(note.title).font(AscentFont.headlineMedium).foregroundColor(MidnightSlate)
                    Text(note.body).font(AscentFont.bodyLarge).foregroundColor(MidnightSlate.opacity(0.9))

                    Divider()
                    Text(note.promptQuestion).font(AscentFont.titleMedium).foregroundColor(MidnightSlate)
                    ForEach(Array(note.promptOptions.enumerated()), id: \.offset) { idx, option in
                        let isPicked = picked == idx
                        let isCorrect = note.promptType == TRAIL_PROMPT_QUIZ && note.correctOption == idx
                        HStack {
                            Text(option).foregroundColor(MidnightSlate)
                            Spacer()
                            if isPicked && note.promptType == TRAIL_PROMPT_QUIZ {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isCorrect ? SuccessGreen : OverdueRed)
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(isPicked ? IceBlueAccent : NeutralFill))
                        .onTapGesture { picked = idx }
                    }
                    if picked != nil, note.promptType == TRAIL_PROMPT_QUIZ, let c = note.correctOption {
                        Text(picked == c ? "That's it." : "The answer: \(note.promptOptions[c])")
                            .font(AscentFont.labelMedium).foregroundColor(RidgelineBlue)
                    }

                    if !note.sources.isEmpty {
                        Divider()
                        Text("Sources").font(AscentFont.labelMedium).foregroundColor(TextMuted)
                        ForEach(Array(note.sources.enumerated()), id: \.offset) { _, s in
                            Text("• \(s)").font(AscentFont.bodySmall).foregroundColor(TextMuted)
                        }
                    }

                    Button {
                        store.trailNotesSeen.insert(note.id)
                        dismiss()
                    } label: {
                        Text("Mark as read").font(AscentFont.titleSmall).foregroundColor(PureWhite)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Capsule().fill(RidgelineBlue))
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .navigationTitle("Trail Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}

// MARK: - Small helper

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
