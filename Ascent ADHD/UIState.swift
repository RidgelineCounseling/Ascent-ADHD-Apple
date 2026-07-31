//
//  UIState.swift
//  Ascent ADHD
//
//  Cross-screen navigation + selection state (the parts of MainApp's `remember` block that drive
//  which screen is shown and which date/week/month is in focus). Kept separate from AppStore so the
//  persisted data model stays clean.
//

import SwiftUI

enum Screen: Hashable { case home, lists, goals, insight }

final class UIState: ObservableObject {
    @Published var screen: Screen = .home
    @Published var selectedDate: CalDate = .today()
    @Published var pickerMonth: CalMonth = .now()
    @Published var showMonthDropdown = false

    // Goals view week/month focus.
    @Published var selectedGoalWeek: CalDate = CalDate.today().previousOrSameMonday
    @Published var selectedGoalMonth: CalMonth = .now()

    // A to-do to briefly highlight after navigating to Lists.
    @Published var highlightedTodoId: String? = nil

    /// Jump to Lists focused on a given date, optionally highlighting an item.
    func openLists(date: CalDate, highlight todoId: String? = nil) {
        selectedDate = date
        highlightedTodoId = todoId
        screen = .lists
    }
}
