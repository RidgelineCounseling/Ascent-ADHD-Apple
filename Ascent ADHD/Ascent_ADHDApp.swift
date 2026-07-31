//
//  Ascent_ADHDApp.swift
//  Ascent ADHD
//

import SwiftUI

@main
struct Ascent_ADHDApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var ui = UIState()

    init() {
        Reminders.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(ui)
        }
    }
}
