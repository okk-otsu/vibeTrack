//
//  DisciplineRow.swift
//  Study
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI
import SwiftData

struct DisciplineRow: View {
    @Environment(\.modelContext) private var modelContext

    let discipline: Discipline
    let isActive: Bool
    let canStart: Bool
    let activeEntry: TimeEntry?

    let onStart: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let sec = StatsService.todaySeconds(
            for: discipline,
            modelContext: modelContext,
            activeEntry: activeEntry
        )

        HStack(spacing: 14) {
            // Play circle (как YPT)
            Button(action: onStart) {
                ZStack {
                    Circle()
                        .fill(Color(hex: discipline.colorHex))
                        .frame(width: 38, height: 38)

                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .offset(x: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(!canStart && !isActive)
            .opacity((!canStart && !isActive) ? 0.35 : 1)

            Text(discipline.name)
                .font(.body)

            Spacer()

            Text(StatsService.formatHMS(sec))
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            // ⋯ menu
            Menu {
                Button("Редактировать предмет") { onEdit() }
                Button("Удалить предмет", role: .destructive) { onDelete() }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
        }
        .contentShape(Rectangle())
    }
}

extension StatsService {
    static func todaySeconds(
        for discipline: Discipline,
        modelContext: ModelContext,
        activeEntry: TimeEntry?
    ) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let end = cal.date(byAdding: .day, value: 1, to: start)!

        let did = discipline.id

        let fd = FetchDescriptor<TimeEntry>(
            predicate: #Predicate { e in
                e.endedAt != nil &&
                e.startedAt >= start && e.startedAt < end &&
                e.discipline?.id == did
            }
        )

        let finished = (try? modelContext.fetch(fd)) ?? []
        var total = finished.reduce(0) { $0 + $1.durationSeconds }

        // если активная запись этой дисциплины началась сегодня — добавляем её время
        if let activeEntry,
           activeEntry.discipline?.id == did,
           activeEntry.startedAt >= start && activeEntry.startedAt < end
        {
            total += max(0, Int(Date.now.timeIntervalSince(activeEntry.startedAt)))
        }

        return total
    }
}
