//
//  TimelineView.swift
//  vibeTrack
//
//  Created by MacBook on 23.02.2026.
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedDate: Date = .now
    @State private var editingEntry: TimeEntry?

    @Query(sort: \TimeEntry.startedAt, order: .forward)
    private var allEntries: [TimeEntry]

    private let hourHeight: CGFloat = 80
    private let startHour = 5
    private let endHour = 24

    private var dayEntries: [TimeEntry] {
        let cal = Calendar.current
        return allEntries.filter {
            cal.isDate($0.startedAt, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Дата",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .padding()

                ScrollView {
                    ZStack(alignment: .topLeading) {
                        hoursGrid

                        ForEach(dayEntries) { entry in
                            entryCard(entry)
                        }
                    }
                    .frame(height: CGFloat(endHour - startHour) * hourHeight)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Таймлайн")
        }
        .sheet(item: $editingEntry) { entry in
            EditEntrySheet(entry: entry)
        }
    }
}

private extension TimelineView {

    var hoursGrid: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(alignment: .top) {
                    Text(hourLabel(hour))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .leading)

                    Rectangle()
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 1)
                        .padding(.top, 8)
                }
                .frame(height: hourHeight, alignment: .top)
            }
        }
    }

    func hourLabel(_ hour: Int) -> String {
        let cal = Calendar.current
        let date = cal.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate)!
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private extension TimelineView {

    func entryCard(_ entry: TimeEntry) -> some View {
        let y = yOffset(for: entry.startedAt)

        return HStack(spacing: 10) {

            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: entry.discipline?.colorHex ?? "#3B82F6"))
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.discipline?.name ?? "Без названия")
                    .font(.headline)

                Text(durationText(entry))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                Button("Изменить…") {
                    editingEntry = entry
                }

                Divider()

                Button("Увеличить на 5 мин") {
                    adjust(entry, delta: 300)
                }

                Button("Уменьшить на 5 мин") {
                    adjust(entry, delta: -300)
                }

                Divider()

                Button("Удалить", role: .destructive) {
                    modelContext.delete(entry)
                    try? modelContext.save()
                }

            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .offset(x: 70, y: y)
    }
}

private extension TimelineView {

    func yOffset(for date: Date) -> CGFloat {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)

        let totalMinutes = (hour - startHour) * 60 + minute
        return CGFloat(totalMinutes) / 60 * hourHeight
    }

    func durationText(_ entry: TimeEntry) -> String {
        print("DRAW:",
              "endedAt:", entry.endedAt as Any,
              "durationSeconds:", entry.durationSeconds,
              "accumulatedSeconds:", entry.accumulatedSeconds)
        let minutes = entry.durationSeconds / 60
        let hours = minutes / 60
        let remaining = minutes % 60

        if hours > 0 {
            return "\(hours)ч \(remaining)м"
        }
        return "\(remaining)м"
    }

    func adjust(_ entry: TimeEntry, delta: Int) {
        let newValue = max(60, entry.durationSeconds + delta)

        entry.endedAt = entry.startedAt.addingTimeInterval(TimeInterval(newValue))

        do {
            try modelContext.save()
        } catch {
            print("Save error:", error)
        }
    }
}


struct EditEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var entry: TimeEntry

    @State private var startAt: Date
    @State private var endAt: Date

    init(entry: TimeEntry) {
        self.entry = entry
        _startAt = State(initialValue: entry.startedAt)
        _endAt = State(initialValue: entry.endedAt ?? entry.startedAt)
    }

    var body: some View {
        VStack {
            DatePicker("Начало", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
            DatePicker("Конец", selection: $endAt, displayedComponents: [.date, .hourAndMinute])

            HStack {
                Button("Отмена") { dismiss() }
                Button("Сохранить") {
                    entry.startedAt = startAt
                    entry.endedAt = endAt

                    let duration = max(0, Int(endAt.timeIntervalSince(startAt)))
                    entry.accumulatedSeconds = duration
                    entry.runningSegmentStartedAt = nil
                    entry.isRunning = false

                    do {
                        try modelContext.save()
                        dismiss()
                    } catch {
                        print("Save error:", error)
                    }
                }
            }
        }
        .padding()
    }
}
