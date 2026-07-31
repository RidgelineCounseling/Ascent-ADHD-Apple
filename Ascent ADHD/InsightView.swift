//
//  InsightView.swift
//  Ascent ADHD
//
//  The "Insight" screen — daily guided reflection, Trail Notes deck, activity heatmap, and derived
//  pattern stats. Ported from the LogInsight branch of MainApp.
//

import SwiftUI

struct InsightView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var ui: UIState

    @State private var reflectionDraft = ""
    @State private var isEditingReflection = false
    @State private var openNote: TrailNote? = nil
    @State private var showSettings = false

    private var today: CalDate { .today() }
    private var todaysPrompt: ReflectionPrompt { reflectionPromptForDate(today) }
    private var existingToday: ReflectionEntry? { store.reflectionEntries.first { $0.date == today } }

    var body: some View {
        ZStack {
            SkyGray.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    reflectionCard
                    recentReflections
                    Divider()
                    trailNotesCard
                    Divider()
                    Text("Your patterns").font(AscentFont.headlineMedium).foregroundColor(MidnightSlate)
                    activityCard
                    statCards
                    disclaimer
                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 16).padding(.vertical, 4)
            }
        }
        .sheet(item: $openNote) { TrailNoteReader(note: $0) }
        .sheet(isPresented: $showSettings) { SettingsSheet() }
        .onAppear {
            reflectionDraft = existingToday?.response ?? ""
            isEditingReflection = existingToday == nil
        }
    }

    private var header: some View {
        HStack {
            Text("Insights").font(AscentFont.displaySmall).foregroundColor(RidgelineBlue)
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape").font(.system(size: 22)).foregroundColor(RidgelineBlue)
            }
        }
        .padding(.top, 8)
    }

    // MARK: Reflection

    private var reflectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil").foregroundColor(RidgelineBlue)
                Text("Today's reflection").font(AscentFont.headlineSmall).foregroundColor(MidnightSlate)
            }
            SurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(todaysPrompt.text).font(AscentFont.titleMedium).foregroundColor(MidnightSlate)
                    if let linkedId = todaysPrompt.linkedNoteId,
                       let linkedNote = SEED_TRAIL_NOTES.first(where: { $0.id == linkedId }) {
                        HStack(spacing: 4) {
                            Image(systemName: "book").font(.system(size: 14))
                            Text("Read the lesson behind this").font(AscentFont.labelMedium).fontWeight(.bold)
                        }
                        .foregroundColor(RidgelineBlue)
                        .onTapGesture { openNote = linkedNote }
                    }
                    if isEditingReflection {
                        TextField("A sentence is plenty…", text: $reflectionDraft, axis: .vertical)
                            .lineLimit(2...5)
                            .padding(10).background(RoundedRectangle(cornerRadius: 16).fill(CardInset))
                        HStack {
                            Button { saveReflection() } label: {
                                Text("Save").fontWeight(.bold).foregroundColor(PureWhite)
                                    .padding(.horizontal, 18).padding(.vertical, 10).background(Capsule().fill(RidgelineBlue))
                            }.disabled(reflectionDraft.trimmed.isEmpty)
                            if existingToday != nil {
                                Button("Cancel") { reflectionDraft = existingToday?.response ?? ""; isEditingReflection = false }
                                    .foregroundColor(TextMuted)
                            }
                        }
                    } else {
                        Text(existingToday?.response ?? "").font(AscentFont.bodyMedium).foregroundColor(MidnightSlate)
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 14)).foregroundColor(SuccessGreen)
                            Text("Saved for today").font(AscentFont.labelSmall).foregroundColor(SuccessGreen)
                            Text("Edit").font(AscentFont.labelMedium).fontWeight(.bold).foregroundColor(RidgelineBlue)
                                .onTapGesture { isEditingReflection = true }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    @ViewBuilder private var recentReflections: some View {
        let recent = store.reflectionEntries.filter { $0.date != today }.sorted { $0.date > $1.date }.prefix(3)
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Recent reflections").font(AscentFont.labelMedium).foregroundColor(MidnightSlate.opacity(0.6))
                ForEach(Array(recent), id: \.id) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.date.month)/\(entry.date.dayOfMonth)  ·  \(entry.prompt)")
                            .font(AscentFont.labelSmall).foregroundColor(MidnightSlate.opacity(0.55))
                        Text(entry.response).font(AscentFont.bodySmall).foregroundColor(MidnightSlate)
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(CardInset))
                }
            }
        }
    }

    // MARK: Trail Notes

    private var trailNotesCard: some View {
        let sequence = trailSequenceForStage(store.journeyStage)
        let nextNote = sequence.first { !store.trailNotesSeen.contains($0.id) }
        let doneCount = sequence.filter { store.trailNotesSeen.contains($0.id) }.count
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "book").foregroundColor(RidgelineBlue)
                    Text("Trail Notes").font(AscentFont.headlineSmall).foregroundColor(MidnightSlate)
                }
                Spacer()
                Text("\(doneCount) / \(sequence.count)").font(AscentFont.labelMedium).foregroundColor(MidnightSlate.opacity(0.5))
            }
            SurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    if let note = nextNote {
                        Text(doneCount == 0 ? "Start here" : "Next note").font(AscentFont.labelMedium).foregroundColor(RidgelineBlue)
                        Text(note.title).font(AscentFont.titleMedium).foregroundColor(MidnightSlate)
                        Button { openNote = note } label: {
                            Text("Read").fontWeight(.bold).foregroundColor(PureWhite)
                                .frame(maxWidth: .infinity).padding(.vertical, 12).background(Capsule().fill(RidgelineBlue))
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "mountain.2").foregroundColor(RidgelineBlue)
                            Text("You've read every Trail Note").font(AscentFont.titleMedium).foregroundColor(MidnightSlate)
                        }
                        Text("More are on the way. Revisit any from the deck.")
                            .font(AscentFont.bodySmall).foregroundColor(MidnightSlate.opacity(0.6))
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: Activity heatmap

    private var activityCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Activity").font(.system(size: 16, weight: .black)).foregroundColor(MidnightSlate)
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach([("30", "30d"), ("90", "90d"), ("ALL", "All")], id: \.0) { value, label in
                            let selected = store.heatmapWindow == value
                            Text(label).font(AscentFont.labelSmall).foregroundColor(selected ? PureWhite : MidnightSlate)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Capsule().fill(selected ? RidgelineBlue : Color(white: 0.85).opacity(0.5)))
                                .onTapGesture { store.heatmapWindow = value }
                        }
                    }
                }
                heatmapGrid
            }
            .padding(16)
        }
    }

    private var heatmapGrid: some View {
        let weeksToShow = store.heatmapWindow == "30" ? 6 : store.heatmapWindow == "90" ? 13 : 20
        let thisMonday = today.previousOrSameMonday
        let startMonday = thisMonday.minusDays(7 * (weeksToShow - 1))
        return HStack(alignment: .top, spacing: 3) {
            VStack(spacing: 3) {
                ForEach(0..<7, id: \.self) { i in
                    Text(["M", "T", "W", "T", "F", "S", "S"][i]).font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray).frame(height: 16)
                }
            }
            .frame(width: 14)
            HStack(spacing: 3) {
                ForEach(0..<weeksToShow, id: \.self) { w in
                    VStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { d in
                            let cellDate = startMonday.plusDays(w * 7 + d)
                            let isFuture = cellDate.isAfter(today)
                            let active = store.activityDates.contains(cellDate.epochDay)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(isFuture ? Color.clear : active ? RidgelineBlue : NeutralFill)
                                .frame(height: 16).frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    // MARK: Stat cards

    private var statCards: some View {
        let activitySet = store.activityDates
        let activeLast30 = (0..<30).filter { activitySet.contains(today.minusDays($0).epochDay) }.count
        var dayCounts: [Int: Int] = [:]
        for offset in 0..<84 {
            let d = today.minusDays(offset)
            if activitySet.contains(d.epochDay) { dayCounts[d.dayOfWeekValue, default: 0] += 1 }
        }
        let names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let topDay = dayCounts.max { $0.value < $1.value }?.key
        let topDayLabel = topDay.map { names[$0 - 1] } ?? "—"
        return HStack(spacing: 10) {
            statCard("\(store.streak)", "day streak")
            statCard("\(activeLast30)", "active days (30d)")
            statCard(topDayLabel, "top day")
        }
    }

    private func statCard(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(AscentFont.headlineMedium).foregroundColor(RidgelineBlue)
            Text(label).font(AscentFont.labelSmall).foregroundColor(MidnightSlate.opacity(0.65)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14).padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(SurfaceContainerLow))
    }

    private var disclaimer: some View {
        Text("Ascent is an education-and-organization tool from Ridgeline Counseling — an adjunct to care, not a treatment or diagnosis.")
            .font(AscentFont.labelSmall).foregroundColor(MidnightSlate.opacity(0.4))
            .padding(.top, 8)
    }

    private func saveReflection() {
        let resp = reflectionDraft.trimmed
        guard !resp.isEmpty else { return }
        if let i = store.reflectionEntries.firstIndex(where: { $0.date == today }) {
            store.reflectionEntries[i].response = resp
            store.reflectionEntries[i].prompt = todaysPrompt.text
        } else {
            store.reflectionEntries.append(ReflectionEntry(date: today, prompt: todaysPrompt.text, response: resp))
        }
        store.recordActivity()
        isEditingReflection = false
    }
}

// MARK: - Settings (reward bank editor + reflection reminder + journey stage)

struct SettingsSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var smallText = ""
    @State private var mediumText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Reward bank — quick rewards (under 5 min)") {
                    ForEach(Array(store.rewardBank.small.enumerated()), id: \.offset) { _, r in Text(r) }
                        .onDelete { store.rewardBank.small.remove(atOffsets: $0) }
                    HStack {
                        TextField("Add a quick reward…", text: $smallText)
                        Button {
                            let t = smallText.trimmed
                            if !t.isEmpty { store.rewardBank.small.append(t); smallText = "" }
                        } label: { Image(systemName: "plus.circle.fill").foregroundColor(RidgelineBlue) }
                    }
                }
                Section("Reward bank — bigger rewards (15+ min)") {
                    ForEach(Array(store.rewardBank.medium.enumerated()), id: \.offset) { _, r in Text(r) }
                        .onDelete { store.rewardBank.medium.remove(atOffsets: $0) }
                    HStack {
                        TextField("Add a bigger reward…", text: $mediumText)
                        Button {
                            let t = mediumText.trimmed
                            if !t.isEmpty { store.rewardBank.medium.append(t); mediumText = "" }
                        } label: { Image(systemName: "plus.circle.fill").foregroundColor(RidgelineBlue) }
                    }
                }
                Section("Daily reflection reminder") {
                    Toggle("Enabled", isOn: $store.reflectionReminderEnabled)
                    if store.reflectionReminderEnabled {
                        Stepper("Hour: \(store.reflectionReminderHour)", value: $store.reflectionReminderHour, in: 0...23)
                        Stepper("Minute: \(store.reflectionReminderMinute)", value: $store.reflectionReminderMinute, in: 0...59, step: 5)
                    }
                }
                Section("Your journey") {
                    Picker("Stage", selection: $store.journeyStage) {
                        Text("Newly diagnosed").tag(TRAIL_STAGE_FOUNDATION)
                        Text("Familiar with my ADHD").tag(TRAIL_STAGE_INMOMENT)
                    }
                }
                Section("Device calendar") {
                    Toggle("Show my calendar events", isOn: $store.showDeviceCalendar)
                        .onChange(of: store.showDeviceCalendar) { _, on in
                            if on { CalendarService.shared.requestAccess { _ in } }
                        }
                }
                BackupSection()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { store.hasCompletedSetup = true; dismiss() } } }
        }
    }
}
