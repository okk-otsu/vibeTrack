////
////  MonthHeatmapView.swift
////  vibeTrack
////
////  Created by MacBook on 22.12.2025.
////
//
//import SwiftUI
//
//struct MonthHeatmapView: View {
//    let monthDate: Date
//    let totals: [Date: Int]
//    @Binding var selectedDay: Date
//
//    private let cal = Calendar.current
//    private let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
//
//    var body: some View {
//        let monthTitle = monthDate.formatted(.dateTime.month(.abbreviated))
//        let days = makeGridDays()
//
//        VStack(spacing: 12) {
//            HStack {
//                Text(monthTitle)
//                    .font(.title3.weight(.semibold))
//                Spacer()
//            }
//
//            HStack {
//                ForEach(["Mon","Tue","Wed","Thu","Fri","Sat","Sun"], id: \.self) { w in
//                    Text(w)
//                        .font(.caption2)
//                        .foregroundStyle(.secondary)
//                        .frame(maxWidth: .infinity)
//                }
//            }
//
//            LazyVGrid(columns: cols, spacing: 6) {
//                ForEach(days, id: \.self) { day in
//                    cell(for: day)
//                }
//            }
//
//            HStack {
//                Spacer()
//                let monthTotal = totals.values.reduce(0,+)
//                Text("\(monthTitle): \(StatsService.formatHM(monthTotal))")
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//            }
//        }
//        .padding()
//        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
//    }
//
//    private func cell(for day: Date) -> some View {
//        let start = cal.startOfDay(for: day)
//        let sec = totals[start, default: 0]
//        let isInMonth = cal.component(.month, from: day) == cal.component(.month, from: monthDate)
//        let isSelected = cal.isDate(start, inSameDayAs: selectedDay)
//
//        return Button {
//            selectedDay = start
//        } label: {
//            VStack(spacing: 6) {
//                Text("\(cal.component(.day, from: day))")
//                    .font(.caption)
//                    .foregroundStyle(isInMonth ? .primary : .secondary)
//                    .opacity(isInMonth ? 1 : 0.4)
//                if sec > 0 {
//                    Text(StatsService.formatHM(sec))
//                        .font(.caption2)
//                        .foregroundStyle(.secondary)
//                } else {
//                    Text(" ")
//                        .font(.caption2)
//                }
//            }
//            .frame(maxWidth: .infinity, minHeight: 44)
//            .padding(.vertical, 8)
//            .background(isInMonth ? heatColor(sec) : Color.clear)
//            .overlay(
//                RoundedRectangle(cornerRadius: 10)
//                    .stroke(isSelected ? Color.primary.opacity(0.7) : .clear, lineWidth: 1)
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 10))
//        }
//        .buttonStyle(.plain)
//        .disabled(!isInMonth)
//        .opacity(isInMonth ? 1 : 0.3)
//    }
//
//    private func heatColor(_ sec: Int) -> Color {
//        let h = Double(sec) / 3600.0
//        if h == 0 { return Color.clear }
//        if h < 1 { return Color.pink.opacity(0.15) }
//        if h < 3 { return Color.pink.opacity(0.28) }
//        if h < 5 { return Color.pink.opacity(0.45) }
//        if h < 7 { return Color.pink.opacity(0.62) }
//        return Color.pink.opacity(0.80)
//    }
//
//    private func makeGridDays() -> [Date] {
//        let comps = cal.dateComponents([.year, .month], from: monthDate)
//        let monthStart = cal.date(from: comps)!
//
//        let range = cal.range(of: .day, in: .month, for: monthStart)!
//        let daysInMonth = range.count
//
//        let weekday = cal.component(.weekday, from: monthStart)
//        let mondayBased = (weekday + 5) % 7  
//
//        var result: [Date] = []
//
//        if mondayBased > 0 {
//            for i in stride(from: mondayBased, to: 0, by: -1) {
//                if let d = cal.date(byAdding: .day, value: -i, to: monthStart) {
//                    result.append(d)
//                }
//            }
//        }
//
//        for day in 0..<daysInMonth {
//            result.append(cal.date(byAdding: .day, value: day, to: monthStart)!)
//        }
//
//        while result.count % 7 != 0 {
//            result.append(cal.date(byAdding: .day, value: 1, to: result.last!)!)
//        }
//
//        return result
//    }
//}
