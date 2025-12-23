//
//  StatsView.swift
//  Study
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI
import SwiftData

struct StatsView: View {

    enum Mode: String, CaseIterable {
        case week = "Week"
        case day  = "Day"
    }

    @Environment(\.modelContext) private var modelContext

    @State private var mode: Mode = .week
    @State private var weekOffset: Int = 0   // 0 = this week, -1 = last week...
    @State private var dayOffset: Int = 0    // 0 = today, -1 = yesterday...

    private let maxWeeksBack = 7
    private let maxDaysBack  = 7

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                #if os(iOS)
                Picker("", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                #endif

                    Group {
                        if mode == .week {
                            VStack(spacing: 14) {
                                weekPager
                                mostUsedWeekCard
                            }
                        } else {
                            VStack(spacing: 14) {
                                dayPager
                                mostUsedDayCard
                            }
                        }
                    }
                #if os(macOS)
                .padding(.top, 12) // единый отступ от сегмента
                #endif
                }
                .padding(.bottom, 24)
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .toolbar {
            #if os(macOS)
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    stepBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!canStepBack)

                Button {
                    stepForward()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!canStepForward)
            }

            ToolbarItem(placement: .principal) {
                Picker("", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            #endif
        }
    }

    
    #if os(macOS)
    private var canStepBack: Bool {
        mode == .week ? weekOffset > -maxWeeksBack : dayOffset > -maxDaysBack
    }

    private var canStepForward: Bool {
        mode == .week ? weekOffset < 0 : dayOffset < 0
    }

    private func stepBack() {
        if mode == .week {
            weekOffset = max(weekOffset - 1, -maxWeeksBack)
        } else {
            dayOffset = max(dayOffset - 1, -maxDaysBack)
        }
    }

    private func stepForward() {
        if mode == .week {
            weekOffset = min(weekOffset + 1, 0)
        } else {
            dayOffset = min(dayOffset + 1, 0)
        }
    }
    #endif
    
    
    // MARK: - Pagers

    private var weekPager: some View {
        #if os(iOS)
        TabView(selection: $weekOffset) {
            ForEach((-maxWeeksBack)...0, id: \.self) { off in
                weekCard(offset: off)
                    .padding(.horizontal)
                    .tag(off)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(minHeight: 320)
        #else
        weekCard(offset: weekOffset)
        .padding(.horizontal)
        #endif
    }

    private var dayPager: some View {
        #if os(iOS)
        TabView(selection: $dayOffset) {
            ForEach((-maxDaysBack)...0, id: \.self) { off in
                dayCard(offset: off)
                    .padding(.horizontal)
                    .tag(off)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(minHeight: 320)
        #else
        dayCard(offset: dayOffset)
        .padding(.horizontal)
        #endif
    }

    // MARK: - Cards

    private func weekCard(offset: Int) -> some View {
        let cal = Calendar.current
        let today = Date()
        let base = cal.date(byAdding: .day, value: offset * 7, to: today) ?? today
        let start = StatsService.weekStart(base)

        let days = StatsService.weekStacks(weekStart: start, modelContext: modelContext)
        let avg = StatsService.weekDailyAverageSeconds(weekStart: start, modelContext: modelContext)
        let delta = StatsService.weekDeltaPercent(weekStart: start, modelContext: modelContext)
        let totalWeek = days.reduce(0) { $0 + $1.totalSeconds }

        return VStack(alignment: .leading, spacing: 12) {

            Text("LESSON TIME")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(weekRangeTitle(for: start)) Average")
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text(prettyForCard(avg))
                    .font(.system(size: 40, weight: .semibold))
                    .monospacedDigit()

                Spacer()

                if let delta {
                    HStack(spacing: 6) {
                        Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                        Text("\(abs(delta)) % from last week")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }

            ScreenTimeWeekChart(days: days, dailyAvgSeconds: avg)

            HStack {
                Text("Total Lesson Time")
                Spacer()
                Text(prettyForCard(totalWeek))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.callout)
            .padding(.horizontal, 4)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func dayCard(offset: Int) -> some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let day = cal.date(byAdding: .day, value: offset, to: today) ?? today

        let hours = StatsService.dayHourStacks(day: day, modelContext: modelContext)
        let total = hours.reduce(0) { $0 + $1.totalSeconds }

        return VStack(alignment: .leading, spacing: 12) {

            Text("LESSON TIME")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .foregroundStyle(.secondary)

            Text(prettyForCard(total))
                .font(.system(size: 40, weight: .semibold))
                .monospacedDigit()

            ScreenTimeDayChart(hours: hours)

            HStack {
                Text("Total Lesson Time")
                Spacer()
                Text(prettyForCard(total))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.callout)
            .padding(.horizontal, 4)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Most Used (separate card)

    private var mostUsedWeekCard: some View {
        let cal = Calendar.current
        let today = Date()
        let base = cal.date(byAdding: .day, value: weekOffset * 7, to: today) ?? today
        let start = StatsService.weekStart(base)

        let top = StatsService.topDisciplinesForWeek(weekStart: start, modelContext: modelContext)

        return MostUsedListView(title: "Most Used", rows: top)
            .padding(.horizontal)
    }

    private var mostUsedDayCard: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let day = cal.date(byAdding: .day, value: dayOffset, to: today) ?? today

        let top = StatsService.topDisciplinesForDay(day: day, modelContext: modelContext)

        return MostUsedListView(title: "Most Used", rows: top)
            .padding(.horizontal)
    }

    // MARK: - Helpers

    private func weekRangeTitle(for weekStart: Date) -> String {
        let cal = Calendar.current
        let weekEnd = cal.date(byAdding: .day, value: 6, to: weekStart)!

        let startDay = cal.component(.day, from: weekStart)
        let endDay = cal.component(.day, from: weekEnd)

        let sameMonth = cal.component(.month, from: weekStart) == cal.component(.month, from: weekEnd)
        let sameYear  = cal.component(.year,  from: weekStart) == cal.component(.year,  from: weekEnd)

        if sameMonth && sameYear {
            let month = weekStart.formatted(.dateTime.month(.abbreviated))
            return "\(startDay)–\(endDay) \(month)"
        } else {
            let startStr = weekStart.formatted(.dateTime.day().month(.abbreviated))
            let endStr   = weekEnd.formatted(.dateTime.day().month(.abbreviated))
            return "\(startStr) – \(endStr)"
        }
    }

    private func prettyForCard(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60

        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
