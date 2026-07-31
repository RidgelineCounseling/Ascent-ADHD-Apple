//
//  ListsView.swift
//  Ascent ADHD
//
//  The "Lists" screen — day priorities (up to 3, with grand reward) + the Other To-Do section
//  (items with subtasks, inline add, complete/reopen). Brain Dump captures a batch of thoughts.
//

import SwiftUI

struct ListsView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var ui: UIState

    @State private var newTodo = ""
    @State private var grandRewardInput = ""
    @State private var expandedTodoIds: Set<String> = []
    @State private var showBrainDump = false
    @State private var editorEntry: ScheduleEntry? = nil
    @State private var presentPriorityEditor = false
    @State private var newPriority = false

    private var day: CalDate { ui.selectedDate }

    private var dayPriorities: [ScheduleEntry] {
        store.scheduleEntries.filter { $0.date == day && $0.isTopPriority }
    }
    private var activeTodos: [OtherTodoItem] {
        store.otherTodoEntries.filter { !$0.isCompleted && $0.date <= day }
    }
    private var completedTodos: [OtherTodoItem] {
        store.otherTodoEntries.filter { $0.isCompleted && $0.completedDate == day }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            SkyGray.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lists").font(AscentFont.displaySmall).foregroundColor(RidgelineBlue)
                        .padding(.top, 8)
                    WeekNavigator()
                    Text("\(day.weekdayFull), \(day.monthFull) \(day.dayOfMonth), \(String(day.year))")
                        .font(AscentFont.titleMedium).foregroundColor(RidgelineBlue)
                    prioritiesCard
                    otherTodoCard
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 16).padding(.vertical, 4)
            }
            brainDumpButton
        }
        .sheet(isPresented: $showBrainDump) { BrainDumpSheet(date: day) }
        .sheet(isPresented: $presentPriorityEditor) {
            TaskEditorSheet(entry: editorEntry, isPriority: newPriority, ownerDate: day)
        }
    }

    // MARK: Priorities

    private var prioritiesCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's Priorities").font(AscentFont.headlineSmall).foregroundColor(MidnightSlate)

                if dayPriorities.count < 3 {
                    addRow(text: "Add a priority…") {
                        editorEntry = nil; newPriority = true; presentPriorityEditor = true
                    }
                }

                if dayPriorities.isEmpty {
                    Text("Nothing set yet. Add up to three above — or use Brain Dump below if your head's full and you want help picking.")
                        .font(AscentFont.bodyMedium).foregroundColor(.gray)
                } else {
                    ForEach(dayPriorities) { p in priorityCard(p) }
                    grandRewardView
                }
            }
            .padding(16)
        }
    }

    private func priorityCard(_ p: ScheduleEntry) -> some View {
        let done = p.isCompleted
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 26)).foregroundColor(PureWhite)
                .onTapGesture { togglePriority(p) }
            VStack(alignment: .leading, spacing: 2) {
                Text(p.task).font(AscentFont.titleLarge).foregroundColor(PureWhite).strikethrough(done)
                if p.hasCustomTime {
                    Text(formatTimeLabel(p.startHour, p.startMinute)).font(AscentFont.bodyMedium).foregroundColor(IceBlueAccent)
                }
                let stepTotal = p.subtasks.count
                if stepTotal > 0 {
                    Text("☑ \(p.subtasks.filter { $0.isCompleted }.count)/\(stepTotal) subtasks")
                        .font(AscentFont.bodyMedium).foregroundColor(IceBlueAccent)
                }
                if !p.reward.isEmpty {
                    Text("🎁 Reward: \(p.reward)").font(AscentFont.bodyMedium).foregroundColor(IceBlueAccent).strikethrough(done)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(done ? RidgelineBlue.opacity(0.5) : RidgelineBlue))
        .contentShape(Rectangle())
        .onTapGesture { editorEntry = p; newPriority = true; presentPriorityEditor = true }
    }

    @ViewBuilder private var grandRewardView: some View {
        let existing = store.dailyGrandRewards[day] ?? ""
        let total = max(dayPriorities.count, 1)
        let completed = dayPriorities.filter { $0.isCompleted }.count
        let fraction = Double(completed) / Double(total)
        if existing.isEmpty {
            VStack(spacing: 6) {
                RewardChipsRow(bank: store.rewardBank, mediumOnly: true) { grandRewardInput = $0 }
                HStack {
                    TextField("Reward for all 3...", text: $grandRewardInput)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(Capsule().fill(CardInset))
                    Button {
                        let t = grandRewardInput.trimmed
                        if !t.isEmpty {
                            store.dailyGrandRewards[day] = t; grandRewardInput = ""
                            store.showNotification("Grand Reward Saved", "Keep up the momentum to claim it!", color: MetricGold, icon: "🏆")
                            store.recordActivity()
                        }
                    } label: {
                        Text("Save").fontWeight(.bold).foregroundColor(PureWhite)
                            .padding(.horizontal, 16).padding(.vertical, 12).background(Capsule().fill(RidgelineBlue))
                    }
                }
            }
        } else {
            ZStack(alignment: .leading) {
                GeometryReader { geo in
                    Capsule().fill(SkyGray)
                    Capsule().fill(fraction >= 1 ? MetricGold.opacity(0.5) : MetricGold.opacity(0.25))
                        .frame(width: max(geo.size.width * max(fraction, 0.01), 4))
                }
                HStack {
                    Text("🏆 \(existing)").font(AscentFont.titleSmall).foregroundColor(MidnightSlate)
                    Spacer()
                    Text("\(completed)/\(total)").font(AscentFont.labelMedium).foregroundColor(MidnightSlate.opacity(0.7))
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 50)
            .clipShape(Capsule())
        }
    }

    // MARK: Other To-Do

    private var otherTodoCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Other To-Do").font(AscentFont.headlineSmall).foregroundColor(MidnightSlate)
                HStack {
                    TextField("Add a to-do…", text: $newTodo)
                        .padding(.horizontal, 14).padding(.vertical, 12).background(Capsule().fill(CardInset))
                    Button { addTodo() } label: {
                        Image(systemName: "plus").foregroundColor(PureWhite).font(.system(size: 18, weight: .bold))
                            .frame(width: 40, height: 40).background(Circle().fill(RidgelineBlue))
                    }
                }
                if activeTodos.isEmpty && completedTodos.isEmpty {
                    Text("No additional tasks written down for today.")
                        .font(AscentFont.bodyMedium).foregroundColor(.gray).padding(.vertical, 8)
                } else {
                    ForEach(activeTodos) { todoRow($0) }
                    ForEach(completedTodos) { completedRow($0) }
                }
            }
            .padding(16)
        }
    }

    private func todoRow(_ item: OtherTodoItem) -> some View {
        let expanded = expandedTodoIds.contains(item.id)
        let subDone = item.subtasks.filter { $0.isCompleted }.count
        let carried = item.date.isBefore(day)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "circle").font(.system(size: 24)).foregroundColor(RidgelineBlue.opacity(0.6))
                    .onTapGesture { completeTodo(item) }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.text).font(AscentFont.titleLarge).foregroundColor(MidnightSlate)
                    if !item.subtasks.isEmpty {
                        Text("☑ \(subDone)/\(item.subtasks.count) subtasks").font(AscentFont.bodyMedium)
                            .foregroundColor(subDone == item.subtasks.count ? SuccessGreen : TextMuted)
                    }
                    if !item.reward.isEmpty {
                        Text("🎁 Reward: \(item.reward)").font(AscentFont.bodyMedium).foregroundColor(TextMuted)
                    }
                    if !item.triggerCue.isEmpty {
                        Text("When I \(item.triggerCue)…").font(AscentFont.bodyMedium).italic().foregroundColor(TextMuted)
                    }
                    if carried { Text("Carried over").font(AscentFont.bodyMedium).foregroundColor(RidgelineBlue) }
                }
                Spacer(minLength: 0)
                if !item.fromBrainDump {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(MidnightSlate.opacity(0.55))
                        .onTapGesture {
                            if expanded { expandedTodoIds.remove(item.id) } else { expandedTodoIds.insert(item.id) }
                        }
                }
            }
            if expanded && !item.fromBrainDump {
                subtaskEditor(item)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(SurfaceContainerHigh))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(white: 0.8).opacity(0.5), lineWidth: 1))
    }

    private func subtaskEditor(_ item: OtherTodoItem) -> some View {
        SubtaskEditorView(item: item)
    }

    private func completedRow(_ item: OtherTodoItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 26)).foregroundColor(SuccessGreen)
                .onTapGesture { reopenTodo(item) }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.text).font(AscentFont.titleLarge).foregroundColor(.gray).strikethrough()
                if !item.reward.isEmpty {
                    Text("🎁 Reward: \(item.reward)").font(AscentFont.bodyMedium).foregroundColor(.gray).strikethrough()
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(SurfaceContainerHigh))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(white: 0.8).opacity(0.5), lineWidth: 1))
    }

    // MARK: Add-row (button styled as a text box)

    private func addRow(text: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "plus").foregroundColor(RidgelineBlue).font(.system(size: 18))
            Text(text).font(AscentFont.titleLarge).foregroundColor(TextHint)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Capsule().fill(CardInset))
        .overlay(Capsule().stroke(BorderGray.opacity(0.6), lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    private var brainDumpButton: some View {
        Button { showBrainDump = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile").foregroundColor(PureWhite)
                Text("Brain Dump").font(.system(size: 15, weight: .black)).foregroundColor(PureWhite)
            }
            .padding(.horizontal, 20).frame(height: 54)
            .background(Capsule().fill(RidgelineBlue))
            .shadow(color: PureBlack.opacity(0.2), radius: 6, y: 3)
        }
        .padding(.trailing, 20).padding(.bottom, 24)
    }

    // MARK: Actions

    private func addTodo() {
        let t = newTodo.trimmed
        guard !t.isEmpty else { return }
        store.otherTodoEntries.append(OtherTodoItem(text: t, date: day))
        newTodo = ""
        store.recordActivity()
    }
    private func completeTodo(_ item: OtherTodoItem) {
        store.updateTodo(item.id) { $0.isCompleted = true; $0.completedDate = day }
        store.awardElevation(ELEVATION_TODO, message: "✓ \(item.text)")
    }
    private func reopenTodo(_ item: OtherTodoItem) {
        store.updateTodo(item.id) { $0.isCompleted = false; $0.completedDate = nil }
        store.removeElevation(ELEVATION_TODO); store.recordActivity()
    }
    private func togglePriority(_ p: ScheduleEntry) {
        let willComplete = !p.isCompleted
        store.updateSchedule(p.id) { $0.isCompleted = willComplete }
        if willComplete { store.awardElevation(ELEVATION_PRIORITY, message: "✓ \(p.task)") }
        else { store.removeElevation(ELEVATION_PRIORITY); store.recordActivity() }
    }
}

// MARK: - Subtask editor (extracted so @State draft is per-row)

struct SubtaskEditorView: View {
    @EnvironmentObject var store: AppStore
    let item: OtherTodoItem
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(item.subtasks) { st in
                HStack {
                    Image(systemName: st.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24)).foregroundColor(st.isCompleted ? SuccessGreen : MidnightSlate.opacity(0.35))
                        .onTapGesture { toggle(st) }
                    Text(st.text).font(AscentFont.bodyLarge)
                        .foregroundColor(st.isCompleted ? TextMuted : MidnightSlate).strikethrough(st.isCompleted)
                    Spacer()
                    Image(systemName: "xmark").font(.system(size: 14)).foregroundColor(.gray.opacity(0.5))
                        .onTapGesture { remove(st) }
                }
            }
            HStack(spacing: 6) {
                TextField("Add a subtask…", text: $draft)
                    .padding(.horizontal, 12).padding(.vertical, 8).background(Capsule().fill(CardInset))
                Button {
                    let t = draft.trimmed
                    if !t.isEmpty {
                        store.updateTodo(item.id) { $0.subtasks.append(TodoSubtask(text: t)) }
                        draft = ""
                    }
                } label: {
                    Image(systemName: "plus").foregroundColor(PureWhite).frame(width: 36, height: 36).background(Circle().fill(RidgelineBlue))
                }
            }
        }
        .padding(.leading, 24)
    }

    private func toggle(_ st: TodoSubtask) {
        store.updateTodo(item.id) { todo in
            if let i = todo.subtasks.firstIndex(where: { $0.id == st.id }) {
                todo.subtasks[i].isCompleted.toggle()
            }
        }
    }
    private func remove(_ st: TodoSubtask) {
        store.updateTodo(item.id) { $0.subtasks.removeAll { $0.id == st.id } }
    }
}

// MARK: - Brain Dump wizard
//
// Two steps, ported from the Android brain-dump dialog:
//   1. Capture — add items one at a time, edit/remove them.
//   2. Prioritize — pick up to (3 − existing priorities) items to elevate to Priorities; the rest
//      become "Other To-Do" items. Selected items are created as (unscheduled) priorities.

struct BrainDumpSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let date: CalDate

    @State private var step = 1
    @State private var draft = ""
    @State private var items: [WizardItem] = []
    @State private var selectedIds: Set<Int64> = []

    private var existingPriorityCount: Int {
        store.scheduleEntries.filter { $0.date == date && $0.isTopPriority }.count
    }
    private var availableSlots: Int { max(3 - existingPriorityCount, 0) }

    var body: some View {
        NavigationStack {
            Group { step == 1 ? AnyView(captureStep) : AnyView(prioritizeStep) }
                .navigationTitle("Brain Dump")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    // Step 1
    private var captureStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Get it all out of your head, one thought at a time.")
                .font(AscentFont.bodyMedium).foregroundColor(TextMuted)
            HStack(spacing: 8) {
                TextField("List your ideas or tasks…", text: $draft)
                    .padding(.horizontal, 14).padding(.vertical, 12).background(Capsule().fill(PureWhite))
                    .overlay(Capsule().stroke(BorderGray.opacity(0.6), lineWidth: 1))
                    .onSubmit(addItem)
                Button(action: addItem) {
                    Image(systemName: "plus").font(.system(size: 22, weight: .bold)).foregroundColor(PureWhite)
                        .frame(width: 48, height: 48).background(Circle().fill(RidgelineBlue))
                }
            }
            ScrollView {
                VStack(spacing: 8) {
                    if items.isEmpty {
                        Text("Your mind palace is clear.").font(AscentFont.bodyMedium).foregroundColor(.gray).padding(.top, 40)
                    } else {
                        ForEach(items) { item in
                            HStack {
                                Text(item.text).font(AscentFont.titleSmall).foregroundColor(MidnightSlate)
                                Spacer()
                                Image(systemName: "xmark").foregroundColor(.gray).font(.system(size: 14))
                                    .onTapGesture { items.removeAll { $0.id == item.id } }
                            }
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(Capsule().fill(PureWhite))
                        }
                    }
                }
            }
            Button {
                if !items.isEmpty { step = 2 }
            } label: {
                Text("Next").fontWeight(.bold).foregroundColor(PureWhite)
                    .frame(maxWidth: .infinity).padding(.vertical, 14).background(Capsule().fill(RidgelineBlue))
            }
            .disabled(items.isEmpty)
            .opacity(items.isEmpty ? 0.5 : 1)
        }
        .padding(20)
    }

    // Step 2
    private var prioritizeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select today's focus blocks").font(AscentFont.headlineSmall).foregroundColor(MidnightSlate)
            if availableSlots > 0 {
                Text("Pick up to \(availableSlots) to elevate to Priorities. The rest move to 'Other To-Do'.")
                    .font(AscentFont.bodyMedium).foregroundColor(.gray)
            } else {
                Text("You already have 3 priorities today — everything here will become a to-do.")
                    .font(AscentFont.bodyMedium).foregroundColor(RidgelineBlue).fontWeight(.bold)
            }
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        let chosen = selectedIds.contains(item.id)
                        let canPick = availableSlots > 0
                        HStack {
                            Image(systemName: chosen ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(chosen ? RidgelineBlue : MistBlue).font(.system(size: 22))
                            Text(item.text).font(AscentFont.titleSmall)
                                .foregroundColor(!canPick && !chosen ? .gray : MidnightSlate)
                            Spacer()
                        }
                        .padding(14)
                        .background(Capsule().fill(chosen ? IceBlueAccent : PureWhite))
                        .overlay(Capsule().stroke(chosen ? RidgelineBlue : Color.clear, lineWidth: 2))
                        .onTapGesture { toggle(item) }
                    }
                }
            }
            Button(action: finish) {
                Text(selectedIds.isEmpty ? "Save to Other To-Do" : "Add \(selectedIds.count) priorit\(selectedIds.count == 1 ? "y" : "ies")")
                    .fontWeight(.bold).foregroundColor(PureWhite)
                    .frame(maxWidth: .infinity).padding(.vertical, 14).background(Capsule().fill(RidgelineBlue))
            }
        }
        .padding(20)
    }

    private func addItem() {
        let t = draft.trimmed
        guard !t.isEmpty else { return }
        items.append(WizardItem(text: t))
        draft = ""
    }
    private func toggle(_ item: WizardItem) {
        if selectedIds.contains(item.id) { selectedIds.remove(item.id) }
        else if selectedIds.count < availableSlots { selectedIds.insert(item.id) }
    }
    private func finish() {
        for item in items {
            if selectedIds.contains(item.id) {
                store.scheduleEntries.append(ScheduleEntry(
                    defaultSlotLabel: "", task: item.text, isTopPriority: true,
                    hasCustomTime: false, date: date))
            } else {
                store.otherTodoEntries.append(OtherTodoItem(text: item.text, date: date, fromBrainDump: true))
            }
        }
        store.recordActivity()
        if selectedIds.isEmpty {
            store.showNotification("Brain Dump Saved", "Items added to your to-do list.", color: RidgelineBlue, icon: "🧠")
        } else {
            store.showNotification("Priorities set", "Elevated \(selectedIds.count) to today's priorities.", color: RidgelineBlue, icon: "🧠")
        }
        dismiss()
    }
}
