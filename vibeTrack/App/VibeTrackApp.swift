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
        }
        .modelContainer(for: [Discipline.self, TimeEntry.self])
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var timerService: TimerService

    var body: some View {
        TabView {
            DisciplineListView()
                .tabItem { Label("Сессии", systemImage: "timer") }

            StatsView()
                .tabItem { Label("Статистика", systemImage: "chart.bar") }
        }
        .onAppear {
            timerService.bind(modelContext: modelContext)
        }
    }
}
