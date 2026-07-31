//
//  ContentView.swift
//  Ascent ADHD
//
//  The app shell — replaces MainApp's Scaffold + NavigationBar with a TabView, and hosts the
//  cross-cutting overlays (in-app notification banner, ascent + milestone celebrations).
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var ui: UIState

    var body: some View {
        ZStack {
            TabView(selection: $ui.screen) {
                HomeView()
                    .tabItem { Label("Schedule", systemImage: "calendar") }
                    .tag(Screen.home)
                ListsView()
                    .tabItem { Label("Lists", systemImage: "checklist") }
                    .tag(Screen.lists)
                GoalsView()
                    .tabItem { Label("Goals", systemImage: "flag") }
                    .tag(Screen.goals)
                InsightView()
                    .tabItem { Label("Insight", systemImage: "lightbulb") }
                    .tag(Screen.insight)
            }
            .tint(RidgelineBlue)

            // In-app banner notification.
            if let note = store.customNotification {
                VStack {
                    NotificationBanner(data: note)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .animation(.spring(response: 0.4), value: store.customNotification?.id)
            }

            // Routine ascent celebration.
            if let ascent = store.ascentCelebration {
                AscentCelebrationView(event: ascent) { store.ascentCelebration = nil }
            }

            // Milestone celebration.
            if let milestone = store.celebrationMilestone {
                MilestoneCelebrationView(milestone: milestone) { store.celebrationMilestone = nil }
            }
        }
    }
}

// MARK: - Notification banner

struct NotificationBanner: View {
    let data: CustomNotificationData
    var body: some View {
        HStack(spacing: 12) {
            Text(data.icon).font(.system(size: 26))
            VStack(alignment: .leading, spacing: 2) {
                Text(data.title).font(AscentFont.titleSmall).foregroundColor(PureWhite)
                Text(data.message).font(AscentFont.bodySmall).foregroundColor(PureWhite.opacity(0.9))
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(data.bgColor))
        .shadow(color: PureBlack.opacity(0.2), radius: 8, y: 4)
        .padding(.top, 8)
    }
}

// MARK: - Ascent celebration (auto-dismisses)

struct AscentCelebrationView: View {
    let event: AscentEvent
    let onDone: () -> Void
    @State private var animate = false

    var body: some View {
        ZStack {
            PureBlack.opacity(0.25).ignoresSafeArea().onTapGesture(perform: onDone)
            VStack(spacing: 10) {
                Text("+\(event.after - event.before) ft")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(MetricGreen)
                    .scaleEffect(animate ? 1 : 0.6)
                if !event.taskLabel.isEmpty {
                    Text(event.taskLabel).font(AscentFont.titleMedium).foregroundColor(MidnightSlate)
                }
                Text("\(event.after) ft").font(AscentFont.labelLarge).foregroundColor(MidnightSlate.opacity(0.6))
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(PureWhite))
            .shadow(radius: 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4)) { animate = true }
            Task { try? await Task.sleep(nanoseconds: 1_600_000_000); onDone() }
        }
    }
}

// MARK: - Milestone celebration (tap to dismiss)

struct MilestoneCelebrationView: View {
    let milestone: Milestone
    let onDone: () -> Void
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [MidnightSlate, RidgelineBlue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Text("⛰️").font(.system(size: 72)).scaleEffect(animate ? 1 : 0.5)
                Text("Milestone reached").font(AscentFont.labelLarge).foregroundColor(PureWhite.opacity(0.8))
                Text(milestone.name).font(.system(size: 34, weight: .black, design: .rounded)).foregroundColor(PureWhite)
                Text("\(milestone.threshold) ft").font(AscentFont.titleLarge).foregroundColor(IceBlueAccent)
                Spacer().frame(height: 8)
                Text("Tap to continue").font(AscentFont.labelMedium).foregroundColor(PureWhite.opacity(0.7))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onDone)
        .onAppear { withAnimation(.spring(response: 0.5)) { animate = true } }
    }
}

// MARK: - Shared date-header row (month label + week strip) used by Home & Lists

struct WeekNavigator: View {
    @EnvironmentObject var ui: UIState

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Button {
                    ui.pickerMonth = CalMonth(year: ui.selectedDate.year, month: ui.selectedDate.month)
                    withAnimation { ui.showMonthDropdown.toggle() }
                } label: {
                    HStack(spacing: 2) {
                        Text(ui.selectedDate.monthShort + (ui.selectedDate.year != CalDate.today().year ? " \(String(ui.selectedDate.year))" : ""))
                            .font(AscentFont.titleMedium).foregroundColor(MidnightSlate)
                        Image(systemName: "chevron.down").font(.system(size: 12)).foregroundColor(MidnightSlate)
                    }
                    .padding(.horizontal, 6).padding(.vertical, 4)
                }
                Spacer().frame(width: 4)
                WeekStripPager()
            }
            .padding(.horizontal, 4)

            if ui.showMonthDropdown {
                DropdownCalendar(monthState: $ui.pickerMonth, selectedDate: ui.selectedDate) { picked in
                    ui.selectedDate = picked
                    ui.showMonthDropdown = false
                }
            }
        }
    }
}

// A swipeable week strip. Uses a TabView pager anchored on the selected date's week.
struct WeekStripPager: View {
    @EnvironmentObject var ui: UIState

    private var weekMonday: CalDate { ui.selectedDate.previousOrSameMonday }

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<7, id: \.self) { offset in
                let date = weekMonday.plusDays(offset)
                WeekStripDay(
                    date: date,
                    isSelected: date == ui.selectedDate,
                    isToday: date == CalDate.today()
                ) { ui.selectedDate = date }
            }
        }
        .frame(maxWidth: .infinity)
        .gesture(DragGesture().onEnded { v in
            if v.translation.width < -60 { ui.selectedDate = ui.selectedDate.plusDays(7) }
            else if v.translation.width > 60 { ui.selectedDate = ui.selectedDate.minusDays(7) }
        })
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStore())
        .environmentObject(UIState())
}
