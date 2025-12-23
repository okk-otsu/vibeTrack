//
//  TimerService.swift
//  Study
//
//  Created by MacBook on 22.12.2025.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class TimerService: ObservableObject {
    @Published private(set) var activeEntry: TimeEntry?
    @Published private(set) var tick: Date = .now

    private var timer: Timer?
    private let stateKey = "active_timer_state_v1"

    func bind(modelContext: ModelContext) {
        // попытка восстановить активную запись после перезапуска
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(ActiveTimerState.self, from: data)
        else { return }

        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate { $0.id == state.entryID }
        )

        if let entry = try? modelContext.fetch(descriptor).first,
           entry.endedAt == nil {
            self.activeEntry = entry
            startTicker()
        } else {
            clearPersistedState()
        }
    }

    func start(discipline: Discipline, modelContext: ModelContext) throws {
        // только одна активная запись
        if activeEntry != nil { return }

        let entry = TimeEntry(discipline: discipline, startedAt: .now)
        modelContext.insert(entry)
        try modelContext.save()

        activeEntry = entry
        persistState(entry: entry, discipline: discipline)
        startTicker()
    }

    func stop(modelContext: ModelContext) throws {
        guard let entry = activeEntry else { return }

        let total = Int(Date.now.timeIntervalSince(entry.startedAt))
        entry.durationSeconds = max(0, total)
        entry.endedAt = .now

        try modelContext.save()

        activeEntry = nil
        stopTicker()
        clearPersistedState()
    }

    func currentElapsedSeconds() -> Int {
        guard let entry = activeEntry else { return 0 }
        return max(0, Int(Date.now.timeIntervalSince(entry.startedAt)))
    }

    // MARK: - ticker

    private func startTicker() {
        if timer != nil { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick = .now
            }
        }
    }

    private func stopTicker() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - persist

    private func persistState(entry: TimeEntry, discipline: Discipline) {
        let state = ActiveTimerState(entryID: entry.id, disciplineID: discipline.id)
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: stateKey)
        }
    }

    private func clearPersistedState() {
        UserDefaults.standard.removeObject(forKey: stateKey)
    }
}
