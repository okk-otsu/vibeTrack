//
//  StatsService.swift
//  Study
//
//  Created by MacBook on 22.12.2025.
//

import Foundation
import SwiftData
import Charts

struct DaySummary {
    let date: Date
    let totalSeconds: Int
    let maxFocusSeconds: Int
    let firstStart: Date?
    let lastEnd: Date?
}

struct DisciplineSlice: Identifiable {
    let id: UUID
    let discipline: Discipline
    let seconds: Int
}

struct StatsService {
    static func dayRange(for date: Date, calendar: Calendar = .current) -> (Date, Date) {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    static func monthRange(containing date: Date, calendar: Calendar = .current) -> (Date, Date) {
        let comps = calendar.dateComponents([.year, .month], from: date)
        let start = calendar.date(from: comps)!
        let end = calendar.date(byAdding: .month, value: 1, to: start)!
        return (start, end)
    }

    // MARK: - Fetch

    static func finishedEntries(in start: Date, _ end: Date, modelContext: ModelContext) -> [TimeEntry] {
        let fd = FetchDescriptor<TimeEntry>(
            predicate: #Predicate { e in
                e.endedAt != nil && e.startedAt >= start && e.startedAt < end
            }
        )
        return (try? modelContext.fetch(fd)) ?? []
    }

    // MARK: - Day

    static func daySummary(date: Date, modelContext: ModelContext) -> DaySummary {
        let (start, end) = dayRange(for: date)
        let entries = finishedEntries(in: start, end, modelContext: modelContext)

        let total = entries.reduce(0) { $0 + $1.durationSeconds }
        let maxFocus = entries.map(\.durationSeconds).max() ?? 0
        let firstStart = entries.map(\.startedAt).min()
        let lastEnd = entries.compactMap(\.endedAt).max()

        return DaySummary(
            date: start,
            totalSeconds: total,
            maxFocusSeconds: maxFocus,
            firstStart: firstStart,
            lastEnd: lastEnd
        )
    }

    static func disciplineBreakdown(date: Date, modelContext: ModelContext) -> [DisciplineSlice] {
        let (start, end) = dayRange(for: date)
        let entries = finishedEntries(in: start, end, modelContext: modelContext)

        var map: [UUID: (Discipline, Int)] = [:]
        for e in entries {
            guard let d = e.discipline else { continue }
            map[d.id, default: (d, 0)].1 += e.durationSeconds
        }

        return map.values
            .map { DisciplineSlice(id: $0.0.id, discipline: $0.0, seconds: $0.1) }
            .sorted { $0.seconds > $1.seconds }
    }

    // MARK: - Month (totals by day)

    static func monthTotals(dateInMonth: Date, modelContext: ModelContext) -> [Date: Int] {
        let cal = Calendar.current
        let (start, end) = monthRange(containing: dateInMonth)
        let entries = finishedEntries(in: start, end, modelContext: modelContext)

        var totals: [Date: Int] = [:]
        for e in entries {
            let day = cal.startOfDay(for: e.startedAt)
            totals[day, default: 0] += e.durationSeconds
        }
        return totals
    }

    // MARK: - Formatting

    static func formatHMS(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }

    static func formatHM(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return String(format: "%d:%02d", h, m) }
        return String(format: "0:%02d", m)
    }
}

extension StatsService {
    static func startOfWeek(for date: Date, calendar: Calendar = .current) -> Date {
        var cal = calendar
        cal.firstWeekday = 2
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps)!
    }

    static func weekRange(containing date: Date, calendar: Calendar = .current) -> (Date, Date) {
        let start = startOfWeek(for: date, calendar: calendar)
        let end = calendar.date(byAdding: .day, value: 7, to: start)!
        return (start, end)
    }

    struct DayPoint: Identifiable {
        let id = UUID()
        let day: Date
        let seconds: Int
    }

    static func weekTotals(dateInWeek: Date, modelContext: ModelContext) -> [DayPoint] {
        let cal = Calendar.current
        let (start, end) = weekRange(containing: dateInWeek)

        let entries = finishedEntries(in: start, end, modelContext: modelContext)

        var totals: [Date: Int] = [:]
        for e in entries {
            let day = cal.startOfDay(for: e.startedAt)
            totals[day, default: 0] += e.durationSeconds
        }

        return (0..<7).map { i in
            let d = cal.date(byAdding: .day, value: i, to: start)!
            return DayPoint(day: d, seconds: totals[cal.startOfDay(for: d), default: 0])
        }
    }
}
extension StatsService {

    struct StackPart: Identifiable {
        let id = UUID()
        let key: String
        let colorHex: String
        let seconds: Int
    }

    struct DayStack: Identifiable {
        let id = UUID()
        let day: Date
        let parts: [StackPart]
        let totalSeconds: Int
    }

    struct HourStack: Identifiable {
        let id = UUID()
        let hour: Int
        let parts: [StackPart]
        let totalSeconds: Int
    }

    // MARK: Week range (Mon..Sun)
    static func weekStart(_ date: Date, cal: Calendar = .current) -> Date {
        var c = cal
        c.firstWeekday = 2
        let comps = c.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return c.date(from: comps)!
    }

    static func weekStacks(weekStart: Date, modelContext: ModelContext) -> [DayStack] {
        let cal = Calendar.current
        let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart)!

        let entries = finishedEntries(in: weekStart, weekEnd, modelContext: modelContext)

        var map: [Date: [String: (hex: String, seconds: Int)]] = [:]

        for e in entries {
            guard let d = e.discipline else { continue }
            let day = cal.startOfDay(for: e.startedAt)
            let key = d.name
            var inner = map[day, default: [:]]
            let prev = inner[key]?.seconds ?? 0
            inner[key] = (hex: d.colorHex, seconds: prev + e.durationSeconds)
            map[day] = inner
        }

        return (0..<7).map { i in
            let day = cal.startOfDay(for: cal.date(byAdding: .day, value: i, to: weekStart)!)
            let inner = map[day, default: [:]]
            let parts = inner.map { StackPart(key: $0.key, colorHex: $0.value.hex, seconds: $0.value.seconds) }
                             .sorted { $0.seconds > $1.seconds }
            let total = parts.reduce(0) { $0 + $1.seconds }
            return DayStack(day: day, parts: parts, totalSeconds: total)
        }
    }

    static func weekTotalSeconds(weekStart: Date, modelContext: ModelContext) -> Int {
        weekStacks(weekStart: weekStart, modelContext: modelContext)
            .reduce(0) { $0 + $1.totalSeconds }
    }

    static func weekDailyAverageSeconds(weekStart: Date, modelContext: ModelContext) -> Int {
        let total = weekTotalSeconds(weekStart: weekStart, modelContext: modelContext)
        return total / 7
    }

    static func weekDeltaPercent(weekStart: Date, modelContext: ModelContext) -> Int? {
        let cal = Calendar.current
        let prevStart = cal.date(byAdding: .day, value: -7, to: weekStart)!
        let curAvg = weekDailyAverageSeconds(weekStart: weekStart, modelContext: modelContext)
        let prevAvg = weekDailyAverageSeconds(weekStart: prevStart, modelContext: modelContext)
        guard prevAvg > 0 else { return nil }
        let pct = Int(((Double(curAvg) - Double(prevAvg)) / Double(prevAvg)) * 100.0)
        return pct
    }

    // MARK: Day stacks by hour (0..23)
    static func dayHourStacks(day: Date, modelContext: ModelContext) -> [HourStack] {
        let cal = Calendar.current
        let (start, end) = dayRange(for: day)
        let entries = finishedEntries(in: start, end, modelContext: modelContext)

        var map: [Int: [String: (hex: String, seconds: Int)]] = [:]

        for e in entries {
            guard let d = e.discipline else { continue }
            let hour = cal.component(.hour, from: e.startedAt)
            let key = d.name
            var inner = map[hour, default: [:]]
            let prev = inner[key]?.seconds ?? 0
            inner[key] = (hex: d.colorHex, seconds: prev + e.durationSeconds)
            map[hour] = inner
        }

        return (0..<24).map { h in
            let inner = map[h, default: [:]]
            let parts = inner.map { StackPart(key: $0.key, colorHex: $0.value.hex, seconds: $0.value.seconds) }
                             .sorted { $0.seconds > $1.seconds }
            let total = parts.reduce(0) { $0 + $1.seconds }
            return HourStack(hour: h, parts: parts, totalSeconds: total)
        }
    }
}

extension StatsService {
    struct TopDisciplineRow: Identifiable {
        let id: PersistentIdentifier
        let name: String
        let colorHex: String
        let seconds: Int
    }

    static func topDisciplines(
        start: Date,
        end: Date,
        modelContext: ModelContext
    ) -> [TopDisciplineRow] {
        let entries = finishedEntries(in: start, end, modelContext: modelContext)

        var map: [PersistentIdentifier: (name: String, hex: String, seconds: Int)] = [:]

        for e in entries {
            guard let d = e.discipline else { continue }
            let key = d.persistentModelID
            let prev = map[key]?.seconds ?? 0
            map[key] = (d.name, d.colorHex, prev + e.durationSeconds)
        }

        return map.map { TopDisciplineRow(id: $0.key, name: $0.value.name, colorHex: $0.value.hex, seconds: $0.value.seconds) }
            .sorted { $0.seconds > $1.seconds }
    }

    static func topDisciplinesForWeek(weekStart: Date, modelContext: ModelContext) -> [TopDisciplineRow] {
        let cal = Calendar.current
        let end = cal.date(byAdding: .day, value: 7, to: weekStart)!
        return topDisciplines(start: weekStart, end: end, modelContext: modelContext)
    }

    static func topDisciplinesForDay(day: Date, modelContext: ModelContext) -> [TopDisciplineRow] {
        let (start, end) = dayRange(for: day)
        return topDisciplines(start: start, end: end, modelContext: modelContext)
    }
}
