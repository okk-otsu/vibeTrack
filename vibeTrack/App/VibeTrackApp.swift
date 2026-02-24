//
//  VibeTrackApp.swift
//  Study
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI
import SwiftData
import Combine

@main
struct VibeTrackApp: App {
    @StateObject private var timerService = TimerService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(timerService)
                .environment(\.locale, Locale(identifier: "ru_RU"))
        }
        .modelContainer(for: [Discipline.self, TimeEntry.self])
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var timerService: TimerService

    var body: some View {
        TabView {
            NavigationStack {
                DisciplineListView()
            }
            .tabItem { Label("Дисциплины", systemImage: "timer") }

            NavigationStack {
                StatsView()
            }
            .tabItem { Label("Статистика", systemImage: "chart.bar") }

            NavigationStack {
                TimelineListScreen()
            }
            .tabItem { Label("Таймлайн", systemImage: "list.bullet.rectangle") }
        }
        .onAppear {
            timerService.bind(modelContext: modelContext)
        }
    }
}
