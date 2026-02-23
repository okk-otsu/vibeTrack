//
//  StatsView.swift
//  Study
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI
import SwiftData

struct StatsView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var weekOffset: Int = 0
    private let maxWeeksBack = 7

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 14) {
                        weekPager
                        mostUsedWeekCard
                    }
                    #if os(macOS)
                    .padding(.top, 12)
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
                    stepBackWeek()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!canStepBackWeek)

                Button {
                    stepForwardWeek()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!canStepForwardWeek)
            }
            #endif
        }
    }

    // MARK: - macOS navigation

    #if os(macOS)
    private var canStepBackWeek: Bool { weekOffset > -maxWeeksBack }
    private var canStepForwardWeek: Bool { weekOffset < 0 }

    private func stepBackWeek() {
        weekOffset = max(weekOffset - 1, -maxWeeksBack)
    }

    private func stepForwardWeek() {
        weekOffset = min(weekOffset + 1, 0)
    }
    #endif

    // MARK: - Pager

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

    // MARK: - Most Used

    private var mostUsedWeekCard: some View {
        let cal = Calendar.current
        let today = Date()
        let base = cal.date(byAdding: .day, value: weekOffset * 7, to: today) ?? today
        let start = StatsService.weekStart(base)

        let top = StatsService.topDisciplinesForWeek(weekStart: start, modelContext: modelContext)

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
