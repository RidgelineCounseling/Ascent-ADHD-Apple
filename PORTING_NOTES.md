# Porting notes — ADHD_Planner (Android/Compose) → Ascent ADHD (iOS/SwiftUI)

This is a faithful first-pass port of the Android app to SwiftUI. It recreates the design system,
data model, persistence, gamification, and the four main screens. Because Xcode isn't available in
the web session, the code is verified by review, not compiled — please build it in Xcode and expect
minor tidy-ups.

## What's ported (structure mirrors the Android source)

| Area | Android (`MainActivity.kt`) | iOS |
| --- | --- | --- |
| Palette + typography | color constants, `RidgelineTypography` | `Theme.swift` |
| Date semantics (`LocalDate`/`LocalTime`/`YearMonth`) | java.time | `DateTypes.swift` (`CalDate`/`CalTime`/`CalMonth`) |
| Data models + JSON | data classes + `toJson`/`fromJson` | `Models.swift` (same JSON keys/format) |
| Trail Notes content | `SEED_TRAIL_NOTES` | `TrailNotes.swift` |
| State + persistence | `remember` + SharedPreferences | `AppStore.swift` (UserDefaults, suite `ridgeline_storage_v7`, same keys) |
| Navigation/date focus | `currentScreen`, `selectedDate`, … | `UIState.swift` |
| Shared components | scoreboard, climb bar/badge, week strip, dropdown calendar, why-chip, reward chips, condensed priorities | `Components.swift` |
| Reminders/notifications | AlarmManager + BroadcastReceiver | `Reminders.swift` (UNUserNotificationCenter) |
| Screens | Home / Lists / Goals / LogInsight | `HomeView`, `ListsView`, `GoalsView`, `InsightView` |
| Shell | Scaffold + NavigationBar | `ContentView.swift` (TabView) + celebration/banner overlays |
| Editors | task composer/detail, goal wizard, note reader | `Editors.swift` |

Persistence uses the **same JSON keys and ISO date strings** as Android, so an exported backup file
is structurally cross-compatible.

## Faithful adaptations (platform differences)

- **Schedule timeline** — Android renders an absolute-positioned, draggable hour grid. This pass
  renders the day as a clean chronological list (same data + interactions: tap to edit, tick to
  complete, color blocks, times). The draggable timeline can be layered on later.
- **Fonts** — Android bundles Inter + Plus Jakarta Sans. iOS uses the system font (rounded for
  headings) at the same sizes/weights, so nothing needs bundling. The `.ttf` files can be added and
  wired into `AscentFont` if pixel-exact type is wanted.
- **Reminders** — mapped from AlarmManager to `UNUserNotificationCenter`.
- **Haptics** — Compose `HapticFeedback` → `UINotificationFeedbackGenerator` / `UIImpactFeedbackGenerator`.

## Deferred to a later pass (present as models/stubs, UI simplified)

- Brain-dump *wizard* (multi-step prioritization flow) — replaced with a simple batch capture for now.
- Focus session (Pomodoro chunking) timer UI — model (`FocusSession`) is ported; overlay pending.
- Device-calendar read-only overlay (Android `CalendarContract`) — the iOS equivalent is EventKit; not wired yet.
- Backup/restore file export/import — data is already JSON-round-tripped; the file picker UI is pending.
- Drag-to-reorder to-dos, and some confirm dialogs (carry-over, subtask→parent completion prompts).

The Xcode project uses file-system-synchronized groups, so every `.swift` file in `Ascent ADHD/` is
picked up automatically — no `project.pbxproj` edits are needed to add more.
