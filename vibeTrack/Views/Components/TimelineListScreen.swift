//
//  TimelineListScreen.swift
//  vibeTrack
//
//  Created by MacBook on 23.02.2026.
//

import SwiftUI
import SwiftData
import Combine

struct TimelineListScreen: View {
    private let hourHeight: CGFloat = 60
    private let minCardHeight: CGFloat = 50   
    private let maxCardHeight: CGFloat = 220
    
    @Environment(\.modelContext) private var modelContext

    @State private var selectedDate: Date = Date()
    @State private var editingEntry: TimeEntry?
    @State private var showEditSheet = false
    @State private var showingAddManualSession = false

    @Query(sort: \TimeEntry.startedAt, order: .forward)
    private var allEntries: [TimeEntry]

    private var dayEntries: [TimeEntry] {
        let cal = Calendar.current
        return allEntries
            .filter { cal.isDate($0.startedAt, inSameDayAs: selectedDate) }
            .sorted { $0.startedAt < $1.startedAt }
    }
    
    private var runningEntryID: UUID? {
        dayEntries
            .filter { $0.isRunning && $0.endedAt == nil }
            .max(by: { $0.startedAt < $1.startedAt })?
            .id
    }

    var body: some View {
        VStack(spacing: 12) {
            header

            ScrollView {
                LazyVStack(spacing: 10) {
                    if dayEntries.isEmpty {
                        Text("Нет сессий за выбранный день")
                            .foregroundStyle(.secondary)
                            .padding(.top, 24)
                    } else {
                        ForEach(dayEntries, id: \.id) { entry in
                            SessionCard(
                                entry: entry,
                                hourHeight: hourHeight,
                                minHeight: minCardHeight,
                                maxHeight: maxCardHeight,
                                onEdit: {
                                    editingEntry = entry
                                    showEditSheet = true
                                },
                                onDelete: { delete(entry) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle("Таймлайн")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddManualSession = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Добавить сессию вручную")
            }
        }
        .sheet(isPresented: $showingAddManualSession) {
            AddManualSessionSheet(date: selectedDate)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEditSheet) {
            if let entry = editingEntry {
                EditEntryTimeSheet(entry: entry)
            } else {
                Text("Не удалось открыть сессию").padding()
            }
        }
        .onChange(of: showEditSheet) { _, newValue in
            if !newValue { editingEntry = nil }
        }
        .padding(.top, 8)
    }
    

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("Дата")
                .foregroundStyle(.secondary)

            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
    
    private func delete(_ entry: TimeEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
}

private struct SessionCard: View {
    let entry: TimeEntry
    let hourHeight: CGFloat
    let minHeight: CGFloat
    let maxHeight: CGFloat

    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var tick: Date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var isActuallyRunning: Bool {
        entry.isRunning && entry.endedAt == nil
    }

    var body: some View {
        let now = tick
        let end = effectiveEnd(now: now)

        let minutes = max(
            0,
            Calendar.current.dateComponents([.minute], from: entry.startedAt, to: end).minute ?? 0
        )

        let height = calculatedHeight(minutes: minutes)

        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: entry.discipline?.colorHex ?? "#3B82F6"))
                .frame(width: 10)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(entry.discipline?.name ?? "Без дисциплины")
                        .font(.headline)

                    if isActuallyRunning {
                        RunningBadge()
                    }
                }

                HStack(spacing: 10) {
                    Text(timeRangeText(end: end))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(durationTextFromMinutes(minutes))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            Spacer(minLength: 8)

            Menu {
                Button("Изменить…") { onEdit() }
                Divider()
                Button("Удалить", role: .destructive) { onDelete() }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(height: height, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.06))
        )
        .onReceive(timer) { tick = $0 }
    }

    private func effectiveEnd(now: Date) -> Date {
        if isActuallyRunning { return now }
        if let endedAt = entry.endedAt { return endedAt }
        return entry.startedAt.addingTimeInterval(TimeInterval(max(0, entry.durationSeconds)))
    }

    private func calculatedHeight(minutes: Int) -> CGFloat {
        let raw = CGFloat(minutes) / 60 * hourHeight
        return min(maxHeight, max(minHeight, raw))
    }

    private func timeRangeText(end: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: entry.startedAt)) – \(f.string(from: end))"
    }

    private func durationTextFromMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 { return "\(h)ч \(m)м" }
        return "\(m)м"
    }
}
private struct RunningBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle().frame(width: 7, height: 7)
            Text("Идёт")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.white.opacity(0.08))
        .clipShape(Capsule())
    }
}
