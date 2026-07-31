//
//  Components.swift
//  Ascent ADHD
//
//  Reusable UI ported from the top-level @Composable helpers in MainActivity.kt:
//  ScoreboardSection, VerticalClimbBar, ClimbTierBadge, WeekStripDay, DropdownCalendar,
//  WhyChip, RewardChipsRow, CondensedPrioritiesCard, StatDisplayItem.
//

import SwiftUI

// MARK: - Card container (approximates Material Card: rounded surface + soft elevation shadow)

struct SurfaceCard<Content: View>: View {
    var fill: Color = SurfaceContainerLow
    var radius: CGFloat = AscentRadius.card
    var elevation: CGFloat = 2
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
                    .shadow(color: PureBlack.opacity(0.10), radius: elevation, x: 0, y: elevation / 2)
            )
    }
}

// Thin progress track (bottom-up or left-right fill).
struct ProgressTrack: View {
    var fraction: Double
    var height: CGFloat = 4
    var fill: Color = MetricGreen
    var track: Color = MistBlue.opacity(0.35)
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(fill)
                    .frame(width: max(geo.size.width * min(max(fraction, 0.02), 1), 2))
            }
        }
        .frame(height: height)
    }
}

// MARK: - ClimbTierBadge

struct ClimbTierBadge: View {
    let tier: Int
    private var labelColor: (String, Color) {
        switch tier {
        case 0: return ("Rested", MistBlue)
        case 1: return ("Climbing", MetricGreen)
        case 2: return ("Strong climb", MetricOrange)
        default: return ("Peak day", MetricBlue)
        }
    }
    var body: some View {
        let (label, color) = labelColor
        VStack(alignment: .trailing, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<(tier == 0 ? 1 : tier), id: \.self) { _ in
                    Text("▲").font(.system(size: 13)).foregroundColor(tier == 0 ? MistBlue : color)
                }
            }
            Text(label).font(AscentFont.labelSmall)
                .foregroundColor(tier == 0 ? MidnightSlate.opacity(0.5) : color)
        }
    }
}

// MARK: - VerticalClimbBar

struct VerticalClimbBar: View {
    let elevation: Int
    let milestone: Milestone
    let next: Milestone?

    private var fraction: Double {
        guard let next = next else { return 1 }
        let span = max(next.threshold - milestone.threshold, 1)
        return Double(min(max(elevation - milestone.threshold, 0), span)) / Double(span)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Capsule().fill(MistBlue.opacity(0.3)).frame(width: 8)
                Capsule().fill(MetricGreen)
                    .frame(width: 8, height: max(geo.size.height * min(max(fraction, 0.02), 1), 4))
                // Next-milestone dot (top)
                Circle().fill(next == nil ? MetricGreen : MistBlue)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(SurfaceContainerLow, lineWidth: 2))
                    .frame(maxHeight: .infinity, alignment: .top)
                // Current-milestone dot (bottom)
                Circle().fill(MetricGreen)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(SurfaceContainerLow, lineWidth: 2))
            }
        }
        .frame(width: 14)
    }
}

// MARK: - ScoreboardSection

struct ScoreboardSection: View {
    let elevation: Int
    let todayCompletions: Int
    let activityDates: Set<Int64>
    let isCondensed: Bool
    let onToggle: () -> Void

    private var milestone: Milestone { currentMilestone(elevation) }
    private var next: Milestone? { nextMilestone(elevation) }
    private var climbTier: Int { todaysClimbTier(todayCompletions) }
    private var fraction: Double {
        guard let next = next else { return 1 }
        let span = max(next.threshold - milestone.threshold, 1)
        return Double(min(max(elevation - milestone.threshold, 0), span)) / Double(span)
    }

    var body: some View {
        SurfaceCard {
            Group { isCondensed ? AnyView(condensed) : AnyView(expanded) }
        }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.easeInOut(duration: 0.24)) { onToggle() } }
    }

    private var condensed: some View {
        HStack(spacing: 10) {
            Text(milestone.name).font(AscentFont.labelMedium).foregroundColor(PureWhite)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(RidgelineBlue))
            Text("\(elevation) ft").font(AscentFont.titleMedium).foregroundColor(MidnightSlate)
            if next != nil {
                ProgressTrack(fraction: fraction).frame(maxWidth: .infinity)
            } else {
                Spacer()
            }
            ClimbTierBadge(tier: climbTier)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private var expanded: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 0) {
                // Left pane: climb bar + milestone/elevation/next
                HStack(spacing: 12) {
                    VerticalClimbBar(elevation: elevation, milestone: milestone, next: next)
                        .padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(milestone.name).font(AscentFont.titleSmall).foregroundColor(RidgelineBlue)
                        HStack(alignment: .lastTextBaseline, spacing: 0) {
                            Text("\(elevation)").font(AscentFont.titleMedium).foregroundColor(MidnightSlate)
                            Text(" ft").font(AscentFont.labelSmall).foregroundColor(MidnightSlate.opacity(0.6))
                        }
                        Spacer().frame(height: 6)
                        if let next = next {
                            Text("Next stop").font(AscentFont.labelSmall).foregroundColor(MidnightSlate.opacity(0.5))
                            Text(next.name).font(AscentFont.titleSmall).foregroundColor(MidnightSlate)
                            Text("\(next.threshold - elevation) ft to go").font(AscentFont.labelMedium).foregroundColor(RidgelineBlue)
                        } else {
                            Text("Peak of the named trail!").font(AscentFont.titleSmall).foregroundColor(RidgelineBlue)
                            Text("Keep climbing").font(AscentFont.labelMedium).foregroundColor(MidnightSlate.opacity(0.6))
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)

                Rectangle().fill(MistBlue.opacity(0.4)).frame(width: 1).padding(.vertical, 8)

                // Right pane: 7-day rhythm
                VStack(spacing: 8) {
                    Text("Last 7 days").font(AscentFont.labelSmall).foregroundColor(MidnightSlate.opacity(0.5))
                    HStack(spacing: 6) {
                        let today = CalDate.today()
                        ForEach((0...6).reversed(), id: \.self) { offset in
                            let day = today.minusDays(offset)
                            let active = activityDates.contains(day.epochDay)
                            let isToday = offset == 0
                            VStack(spacing: 4) {
                                Text(day.weekdayNarrow).font(AscentFont.labelSmall)
                                    .foregroundColor(isToday ? RidgelineBlue : MidnightSlate.opacity(0.4))
                                Circle()
                                    .fill(active ? MetricGreen : Color.clear)
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(isToday ? RidgelineBlue : MistBlue, lineWidth: active ? 0 : 1.5))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.leading, 12)
            }
            .frame(height: 104)

            ClimbTierBadge(tier: climbTier)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

// MARK: - WeekStripDay

struct WeekStripDay: View {
    let date: CalDate
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 1) {
            Text(date.weekdayNarrow).font(.system(size: 9, weight: .medium))
                .foregroundColor(isSelected ? RidgelineBlue : MidnightSlate.opacity(0.5))
            Text("\(date.dayOfMonth)").font(AscentFont.titleSmall)
                .foregroundColor(isSelected ? PureWhite : MidnightSlate)
                .frame(width: 28, height: 28)
                .background(Circle().fill(isSelected ? RidgelineBlue : Color.clear))
                .overlay(Circle().stroke(!isSelected && isToday ? RidgelineBlue : Color.clear, lineWidth: 1.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - DropdownCalendar

struct DropdownCalendar: View {
    @Binding var monthState: CalMonth
    let selectedDate: CalDate
    let onDayPick: (CalDate) -> Void

    var body: some View {
        SurfaceCard(fill: SurfaceContainerHigh, radius: AscentRadius.cardLarge, elevation: 1) {
            VStack(spacing: 8) {
                HStack {
                    Button { withAnimation { monthState = monthState.minusMonths(1) } } label: {
                        Text("◀").fontWeight(.bold).foregroundColor(RidgelineBlue)
                    }
                    Spacer()
                    Text("\(monthState.monthFull) \(String(monthState.year))")
                        .font(AscentFont.titleMedium).foregroundColor(MidnightSlate)
                    Spacer()
                    Button { withAnimation { monthState = monthState.plusMonths(1) } } label: {
                        Text("▶").fontWeight(.bold).foregroundColor(RidgelineBlue)
                    }
                }
                HStack {
                    ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, d in
                        Text(d).font(AscentFont.labelSmall).foregroundColor(MidnightSlate.opacity(0.5))
                            .frame(maxWidth: .infinity)
                    }
                }
                grid
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .gesture(DragGesture().onEnded { v in
                if v.translation.width < -60 { withAnimation { monthState = monthState.plusMonths(1) } }
                else if v.translation.width > 60 { withAnimation { monthState = monthState.minusMonths(1) } }
            })
        }
        .padding(.vertical, 4)
    }

    private var grid: some View {
        let daysInMonth = monthState.lengthOfMonth
        let prefix = (monthState.firstDayOfWeekValue - 1) % 7
        let total = prefix + daysInMonth
        let rows = Int(ceil(Double(total) / 7.0))
        return VStack(spacing: 2) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let slot = row * 7 + col
                        let dayNum = slot - prefix + 1
                        if slot < prefix || dayNum > daysInMonth {
                            Color.clear.frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                        } else {
                            let cellDate = monthState.atDay(dayNum)
                            let isSelected = cellDate == selectedDate
                            let isToday = cellDate == CalDate.today()
                            Text("\(dayNum)").font(AscentFont.labelMedium)
                                .foregroundColor(isSelected ? PureWhite : MidnightSlate)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .background(Circle().fill(isSelected ? RidgelineBlue : Color.clear).padding(2))
                                .overlay(Circle().stroke(!isSelected && isToday ? RidgelineBlue : Color.clear, lineWidth: 1.5).padding(2))
                                .contentShape(Rectangle())
                                .onTapGesture { onDayPick(cellDate) }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - WhyChip

struct WhyChip: View {
    let title: String
    let explanation: String
    @State private var show = false

    var body: some View {
        Text("?").font(.system(size: 12, weight: .bold)).foregroundColor(RidgelineBlue)
            .frame(width: 18, height: 18)
            .background(Circle().fill(RidgelineBlue.opacity(0.12)))
            .onTapGesture { show = true }
            .alert(title, isPresented: $show) {
                Button("Got it", role: .cancel) { }
            } message: {
                Text(explanation)
            }
    }
}

// MARK: - RewardChipsRow

struct RewardChipsRow: View {
    let bank: RewardBank
    var mediumOnly: Bool = false
    var smallOnly: Bool = false
    let onPick: (String) -> Void

    private var items: [String] {
        if mediumOnly { return bank.medium }
        if smallOnly { return bank.small }
        return bank.small + bank.medium
    }

    var body: some View {
        if !items.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, reward in
                        Text(reward).font(AscentFont.labelMedium).foregroundColor(MidnightSlate).lineLimit(1)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Capsule().fill(IceBlueAccent))
                            .onTapGesture { onPick(reward) }
                    }
                }
            }
        }
    }
}

// MARK: - CondensedPrioritiesCard

struct CondensedPrioritiesCard: View {
    let priorities: [ScheduleEntry]
    let onPriorityTap: (ScheduleEntry) -> Void

    private var total: Int { priorities.count }
    private var done: Int { priorities.filter { $0.isCompleted }.count }
    private var fraction: Double { total > 0 ? Double(done) / Double(total) : 0 }
    private var allDone: Bool { total > 0 && done == total }

    var body: some View {
        SurfaceCard {
            if allDone {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(SuccessGreen).font(.system(size: 18))
                    Text("Priorities complete for today").font(AscentFont.titleSmall).foregroundColor(SuccessGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12).padding(.vertical, 10)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Text("Priorities").font(AscentFont.labelMedium).foregroundColor(PureWhite)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(RidgelineBlue))
                        if total > 0 {
                            Text("\(done) / \(total)").font(AscentFont.labelMedium).foregroundColor(MidnightSlate.opacity(0.7))
                        }
                        Spacer()
                        if total > 0 {
                            ProgressTrack(fraction: fraction).frame(width: 48)
                        }
                    }
                    if priorities.isEmpty {
                        Text("None set").font(AscentFont.labelMedium).foregroundColor(MidnightSlate.opacity(0.5))
                            .padding(.horizontal, 4).padding(.vertical, 2)
                    } else {
                        ForEach(priorities) { entry in
                            HStack {
                                Text(entry.task).font(AscentFont.labelMedium).foregroundColor(PureWhite)
                                    .lineLimit(1)
                                    .strikethrough(entry.isCompleted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if entry.isCompleted {
                                    Image(systemName: "checkmark").foregroundColor(PureWhite).font(.system(size: 16))
                                }
                            }
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(Capsule().fill(entry.isCompleted ? RidgelineBlue.opacity(0.5) : RidgelineBlue))
                            .contentShape(Rectangle())
                            .onTapGesture { onPriorityTap(entry) }
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
            }
        }
    }
}

// MARK: - StatDisplayItem

struct StatDisplayItem: View {
    let icon: String
    let label: String
    let value: String
    let valueColor: Color
    var isCondensed: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Text(icon).font(.system(size: 14))
                Text(value).font(.system(size: 16, weight: .black)).foregroundColor(valueColor)
            }
            if !isCondensed {
                Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(RidgelineBlue)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}

// MARK: - Small reusable checkbox (subtask / step rows — consistent per design rules)

struct AscentCheckbox: View {
    let isChecked: Bool
    var size: CGFloat = 22
    let onToggle: () -> Void
    var body: some View {
        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
            .font(.system(size: size))
            .foregroundColor(isChecked ? SuccessGreen : MistBlue)
            .onTapGesture(perform: onToggle)
    }
}
