//
//  ScreenTimeDayChart.swift
//  vibeTrack
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI
import Charts

struct ScreenTimeDayChart: View {
    let hours: [StatsService.HourStack]

    private var maxMinutes: Double {
        let maxHour = hours.map(\.totalSeconds).max() ?? 0
        return niceUpperMinutes(for: maxHour)
    }

    var body: some View {
        Chart {
            ForEach(hours) { h in
                ForEach(h.parts) { part in
                    BarMark(
                        x: .value("Hour", h.hour),
                        y: .value("Minutes", Double(part.seconds) / 60.0)
                    )
                    .foregroundStyle(Color(hex: part.colorHex))
                    .position(by: .value("Discipline", part.key))
                }
            }
        }
        .chartYScale(domain: 0...maxMinutes)
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                if let v = value.as(Double.self) {
                    AxisGridLine()
                    AxisValueLabel {
                        let m = Int(v)
                        if m == 0 { Text("0") }
                        else { Text("\(m)m") }
                    }
                }
            }
        }
        .chartYAxis {
            let top = maxMinutes
            let ticks: [Double] = (top <= 60) ? [0, 30, 60] : [0, top / 2, top]

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
        .frame(height: 140)
    }
    
    private func niceUpperMinutes(for maxSeconds: Int) -> Double {
        let m = Double(maxSeconds) / 60.0

        // ступени как в Screen Time
        let steps: [Double] = [60, 120, 240, 360, 480, 720, 960, 1440] // 1h,2h,4h,6h,8h,12h,16h,24h
        for s in steps {
            if m <= s { return s }
        }
        // если вдруг больше суток — округлим вверх до ближайших 6 часов
        let step = 360.0
        return ceil(m / step) * step
    }
}
