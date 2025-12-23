//
//  ScreenTimeWeekChart.swift
//  vibeTrack
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI
import Charts

struct ScreenTimeWeekChart: View {
    let days: [StatsService.DayStack]
    let dailyAvgSeconds: Int

    private var maxMinutes: Double {
        let maxDay = days.map(\.totalSeconds).max() ?? 0
        let maxVal = max(maxDay, dailyAvgSeconds)
        return niceUpperMinutes(for: maxVal)
    }

    var body: some View {
        Chart {
            ForEach(days) { day in
                ForEach(day.parts) { part in
                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value("Minutes", Double(part.seconds) / 60.0),
                        width: .fixed(14) // ближе к Screen Time
                    )
                    .foregroundStyle(Color(hex: part.colorHex))
                }
            }

            RuleMark(y: .value("avg", Double(dailyAvgSeconds) / 60.0))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(.green.opacity(0.9))
                .annotation(position: .trailing) {
                    Text("avg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
        }
        .chartYScale(domain: 0...maxMinutes)
        .chartPlotStyle { plot in
            plot.padding(.vertical, 4)
        }

        .chartYAxis {
            let top = maxMinutes
            let ticks: [Double] = (top <= 60)
                ? [0, 20, 40, 60]
                : [0, top / 2, top]

            AxisMarks(position: .trailing, values: ticks) { value in
                if let v = value.as(Double.self) {
                    AxisGridLine()
                    AxisValueLabel {
                        if v == 0 { Text("0") }
                        else if top <= 60 { Text("\(Int(v))m") }
                        else { Text("\(Int(v / 60))h") }
                    }
                }
            }
        }

        .chartXAxis {
            AxisMarks(values: days.map { $0.day }) { v in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                AxisValueLabel {
                    if let d = v.as(Date.self) {
                        Text(d.formatted(.dateTime.weekday(.narrow)))
                    }
                }
            }
        }

        .frame(height: 140)
    }

    private func niceUpperMinutes(for maxSeconds: Int) -> Double {
        let m = Double(maxSeconds) / 60.0
        let steps: [Double] = [60, 120, 240, 360, 480, 720, 960, 1440]
        for s in steps { if m <= s { return s } }
        return ceil(m / 360.0) * 360.0
    }
}
