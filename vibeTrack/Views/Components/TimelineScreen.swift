//
//  TimelineScreen.swift
//  vibeTrack
//
//  Created by MacBook on 23.02.2026.
//

import SwiftUI
import SwiftData

struct TimelineScreen: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedDate: Date = .now
    @State private var editingEntry: TimeEntry?

    @Query(sort: \TimeEntry.startedAt, order: .forward)
    private var allEntries: [TimeEntry]

    private let hourHeight: CGFloat = 48
    private let startHour = 0
    private let endHour = 24

    private var dayEntries: [TimeEntry] {
        let cal = Calendar.current
        return allEntries.filter { cal.isDate($0.startedAt, inSameDayAs: selectedDate) }
    }

    var body: some View {
        VStack(spacing: 12) {
            header

            ScrollView {
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        hoursGrid

                        ForEach(dayEntries) { entry in
                            TimelineEntryRow(
                                entry: entry,
                                startHour: startHour,
                                hourHeight: hourHeight,
                                contentWidth: geo.size.width,     // 👈 добавили
                                onEdit: { editingEntry = entry },
                                onAdjust: { delta in adjustDuration(entry: entry, deltaSeconds: delta) },
                                onDelete: { delete(entry) }
                            )
                        }
                    }
                    .frame(height: CGFloat(endHour - startHour) * hourHeight)
                }
                .frame(height: CGFloat(endHour - startHour) * hourHeight) // важно: чтобы GeometryReader имел высоту
                .padding(.horizontal, 16)
            }
        }
        .sheet(item: $editingEntry) { entry in
            EditEntryDurationSheet(entry: entry)
        }
        .padding(.top, 8)
    }

    private var header: some View {
        HStack {
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .labelsHidden()

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var hoursGrid: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 12) {
                    Text(hourLabel(hour))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 62, alignment: .leading)

                    Rectangle()
                        .fill(.white.opacity(0.07))
                        .frame(height: 1)
                        .padding(.top, 8)
                }
                .frame(height: hourHeight, alignment: .top)
            }
        }
    }

    private func hourLabel(_ h: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let cal = Calendar.current
        let d = cal.date(bySettingHour: h % 24, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        return formatter.string(from: d)
    }

    private func adjustDuration(entry: TimeEntry, deltaSeconds: Int) {
        // Меняем именно "время за подход" => durationSeconds
        let newValue = max(60, entry.durationSeconds + deltaSeconds) // минимум 1 мин (можешь сделать 0)
        entry.durationSeconds = newValue

        // endedAt синхронизируем (чтобы таймлайн потом мог рисовать высоту по реальному end)
        entry.endedAt = entry.startedAt.addingTimeInterval(TimeInterval(newValue))

        try? modelContext.save()
    }

    private func delete(_ entry: TimeEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
}

private struct TimelineEntryRow: View {
    let entry: TimeEntry
    let startHour: Int
    let hourHeight: CGFloat
    let contentWidth: CGFloat

    let onEdit: () -> Void
    let onAdjust: (Int) -> Void
    let onDelete: () -> Void

    private let leftGutter: CGFloat = 74   // место под часы слева (как у тебя было offset x)
    private let minBlockHeight: CGFloat = 36

    var body: some View {
        let y = yOffset(for: entry.startedAt)
        let h = blockHeight(seconds: entry.durationSeconds)
        let w = max(200, contentWidth - leftGutter - 16) // 16 — правый запас, чтобы ⋯ не улетал

        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: entry.discipline?.colorHex ?? "#3B82F6"))
                .frame(width: 6, height: h)            // ✅ фиксируем высоту полоски

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.discipline?.name ?? "Без дисциплины")
                    .font(.headline)

                Text(durationText(entry.durationSeconds))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Menu {
                Button("Изменить…") { onEdit() }

                Divider()

                Button("Увеличить на 5 мин") { onAdjust(+5 * 60) }
                Button("Уменьшить на 5 мин") { onAdjust(-5 * 60) }

                Divider()

                Button("Удалить", role: .destructive) { onDelete() }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)      // ✅ фиксируем hit-area
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(width: w, height: h, alignment: .leading)  // ✅ фиксируем высоту карточки
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.06))
        )
        .offset(x: leftGutter, y: y)
    }

    private func yOffset(for date: Date) -> CGFloat {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)

        let minutesFromStart = (hour - startHour) * 60 + minute
        let y = CGFloat(minutesFromStart) / 60 * hourHeight

        // ограничим в пределах дня
        let maxY = CGFloat(24) * hourHeight - 1
        return min(max(y, 0), maxY)
    }

    private func blockHeight(seconds: Int) -> CGFloat {
        // высота пропорциональна длительности: hourHeight пикселей = 60 минут
        let minutes = CGFloat(max(0, seconds)) / 60
        let raw = minutes / 60 * hourHeight
        return max(minBlockHeight, raw) // чтобы 1 минута была видимой "плашкой"
    }

    private func durationText(_ seconds: Int) -> String {
        let m = max(0, seconds) / 60
        let h = m / 60
        let mm = m % 60
        if h > 0 { return "\(h)ч \(mm)м" }
        return "\(mm)м"
    }
}
