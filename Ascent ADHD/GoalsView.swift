//
//  GoalsView.swift
//  Ascent ADHD
//
//  The "Goals" screen — weekly + monthly goals made of steps with deadlines / rewards / a future
//  vision. Ported from the Goals branch of MainApp.
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var ui: UIState

    @State private var weeklyExpanded = true
    @State private var monthlyExpanded = true
    @State private var editorGoal: GoalEntry? = nil
    @State private var editorType = "WEEKLY"
    @State private var presentEditor = false
    @State private var pendingCompletion: GoalEntry? = nil

    private var week: CalDate { ui.selectedGoalWeek }
    private var month: CalMonth { ui.selectedGoalMonth }

    private var weeklyGoals: [GoalEntry] {
        store.goalEntries.filter { $0.type == "WEEKLY" && $0.weekAnchor == week }
            .sorted { !$0.isCompleted && $1.isCompleted }
    }
    private var monthlyGoals: [GoalEntry] {
        store.goalEntries.filter { $0.type == "MONTHLY" && $0.monthAnchor == month }
            .sorted { !$0.isCompleted && $1.isCompleted }
    }

    var body: some View {
        ZStack {
            SkyGray.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Goals").font(AscentFont.displaySmall).foregroundColor(RidgelineBlue).padding(.top, 8)

                    weeklySection
                    monthlySection
                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 16).padding(.vertical, 4)
            }
        }
        .sheet(isPresented: $presentEditor) {
            GoalEditorSheet(goal: editorGoal, type: editorType,
                            weekAnchor: editorType == "WEEKLY" ? week : nil,
                            monthAnchor: editorType == "MONTHLY" ? month : nil)
        }
        .alert("Complete this goal?", isPresented: Binding(get: { pendingCompletion != nil }, set: { if !$0 { pendingCompletion = nil } })) {
            Button("Complete") { if let g = pendingCompletion { finishGoal(g) }; pendingCompletion = nil }
            Button("Cancel", role: .cancel) { pendingCompletion = nil }
        } message: {
            Text(pendingCompletion?.title ?? "")
        }
    }

    // MARK: Weekly

    private var weeklySection: some View {
        let weekEnd = week.plusDays(6)
        let label = "Week of \(week.monthShort) \(week.dayOfMonth) - \(weekEnd.monthShort) \(weekEnd.dayOfMonth)"
        return SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Weekly Goals").font(AscentFont.headlineSmall).foregroundColor(MidnightSlate)
                    Spacer()
                    HStack(spacing: 14) {
                        Button { ui.selectedGoalWeek = week.minusDays(7) } label: { Image(systemName: "chevron.left") }
                        Button { ui.selectedGoalWeek = week.plusDays(7) } label: { Image(systemName: "chevron.right") }
                    }.foregroundColor(RidgelineBlue)
                }
                Text(label).font(AscentFont.titleMedium).foregroundColor(RidgelineBlue)

                addRow(text: "Set a weekly goal…") {
                    editorGoal = nil; editorType = "WEEKLY"; presentEditor = true
                }
                if weeklyGoals.isEmpty {
                    Text("No weekly goals mapped out yet.").font(AscentFont.bodyMedium).foregroundColor(.gray)
                } else {
                    ForEach(weeklyGoals) { goalCard($0) }
                }
            }
            .padding(16)
        }
    }

    // MARK: Monthly

    private var monthlySection: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Monthly Goals").font(AscentFont.headlineSmall).foregroundColor(MidnightSlate)
                    Spacer()
                    HStack(spacing: 14) {
                        Button { ui.selectedGoalMonth = month.minusMonths(1) } label: { Image(systemName: "chevron.left") }
                        Button { ui.selectedGoalMonth = month.plusMonths(1) } label: { Image(systemName: "chevron.right") }
                    }.foregroundColor(RidgelineBlue)
                }
                Text("\(month.monthFull) \(String(month.year))").font(AscentFont.titleMedium).foregroundColor(RidgelineBlue)

                addRow(text: "Set a monthly goal…") {
                    editorGoal = nil; editorType = "MONTHLY"; presentEditor = true
                }
                if monthlyGoals.isEmpty {
                    Text("No monthly goals mapped out yet.").font(AscentFont.bodyMedium).foregroundColor(.gray)
                } else {
                    ForEach(monthlyGoals) { goalCard($0) }
                }
            }
            .padding(16)
        }
    }

    // MARK: Goal card

    private func goalCard(_ goal: GoalEntry) -> some View {
        let today = CalDate.today()
        let late = (goal.deadlineDate.map { $0.isBefore(today) } ?? false) && !goal.isCompleted
        let soon = goal.deadlineDate.map { $0 == today || $0 == today.plusDays(1) } ?? false
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 26)).foregroundColor(goal.isCompleted ? SuccessGreen : RidgelineBlue.opacity(0.6))
                        .onTapGesture { toggleGoal(goal) }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.title).font(AscentFont.titleLarge)
                            .foregroundColor(goal.isCompleted ? .gray : MidnightSlate).strikethrough(goal.isCompleted)
                        if let d = goal.deadlineDate {
                            Text("Due: \(d.month)/\(d.dayOfMonth)").font(AscentFont.bodyMedium)
                                .foregroundColor(goal.isCompleted ? .gray : late ? .red : soon ? MetricOrange : RidgelineBlue)
                        }
                    }
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "pencil").foregroundColor(RidgelineBlue)
                        .onTapGesture { editorGoal = goal; editorType = goal.type; presentEditor = true }
                    Image(systemName: "xmark").foregroundColor(.gray.opacity(0.6))
                        .onTapGesture { store.goalEntries.removeAll { $0.id == goal.id } }
                }
            }

            if !goal.futureVision.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("✨ When this is done").font(AscentFont.bodyMedium).foregroundColor(RidgelineBlue)
                    Text(goal.futureVision).font(AscentFont.bodyMedium).foregroundColor(MidnightSlate)
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14).fill(NeutralFill))
            }

            if !goal.steps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(goal.steps) { step in stepRow(goal, step) }
                }
                .padding(.leading, 24)
            }
            GoalStepAdder(goal: goal)
                .padding(.leading, 24)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(SurfaceContainerHigh))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(white: 0.8).opacity(0.5), lineWidth: 1))
    }

    private func stepRow(_ goal: GoalEntry, _ step: GoalStep) -> some View {
        let today = CalDate.today()
        let late = (step.deadlineDate.map { $0.isBefore(today) } ?? false) && !step.isCompleted
        let soon = step.deadlineDate.map { $0 == today || $0 == today.plusDays(1) } ?? false
        return HStack {
            Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 26)).foregroundColor(step.isCompleted ? SuccessGreen : MidnightSlate.opacity(0.35))
                .onTapGesture { toggleStep(goal, step) }
            Text(step.text).font(AscentFont.bodyLarge)
                .foregroundColor(step.isCompleted ? .gray : MidnightSlate).strikethrough(step.isCompleted)
            Spacer()
            if let d = step.deadlineDate {
                Text("\(d.month)/\(d.dayOfMonth)").font(AscentFont.bodyMedium)
                    .foregroundColor(step.isCompleted ? .gray : late ? .red : soon ? MetricOrange : RidgelineBlue)
            }
        }
    }

    private func addRow(text: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "plus").foregroundColor(RidgelineBlue)
            Text(text).font(AscentFont.titleLarge).foregroundColor(TextHint)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Capsule().fill(CardInset))
        .overlay(Capsule().stroke(BorderGray.opacity(0.6), lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    // MARK: Actions

    private func toggleGoal(_ goal: GoalEntry) {
        if goal.isCompleted {
            store.updateGoal(goal.id) { $0.isCompleted = false }
            store.removeElevation(ELEVATION_PRIORITY); store.recordActivity()
        } else {
            pendingCompletion = goal
        }
    }
    private func finishGoal(_ goal: GoalEntry) {
        store.updateGoal(goal.id) { $0.isCompleted = true }
        store.awardElevation(ELEVATION_PRIORITY, message: "🏁 \(goal.title)")
    }
    private func toggleStep(_ goal: GoalEntry, _ step: GoalStep) {
        var nowDone = false
        store.updateGoal(goal.id) { g in
            if let i = g.steps.firstIndex(where: { $0.id == step.id }) {
                g.steps[i].isCompleted.toggle(); nowDone = g.steps[i].isCompleted
            }
        }
        if nowDone { store.awardElevation(ELEVATION_STEP, message: "✨ Step done · +\(ELEVATION_STEP) ft") }
        else { store.removeElevation(ELEVATION_STEP); store.recordActivity() }
    }
}

// MARK: - Inline step adder (per-goal @State)

struct GoalStepAdder: View {
    @EnvironmentObject var store: AppStore
    let goal: GoalEntry
    @State private var draft = ""

    var body: some View {
        HStack(spacing: 6) {
            TextField("Add a step…", text: $draft)
                .padding(.horizontal, 12).padding(.vertical, 8).background(Capsule().fill(CardInset))
            Button {
                let t = draft.trimmed
                if !t.isEmpty {
                    store.updateGoal(goal.id) { $0.steps.append(GoalStep(text: t)) }
                    draft = ""; store.recordActivity()
                }
            } label: {
                Image(systemName: "plus").foregroundColor(PureWhite).frame(width: 36, height: 36).background(Circle().fill(RidgelineBlue))
            }
        }
        .padding(.top, 8)
    }
}
