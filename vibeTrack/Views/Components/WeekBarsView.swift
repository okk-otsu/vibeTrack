//
//  WeekBarsView.swift
//  vibeTrack
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI
import Charts

struct WeekBarsView: View {
    let points: [StatsService.DayPoint]

    var body: some View {
        let total = points.reduce(0) { $0 + $1.seconds }

        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Week")
                    .font(.headline)

                Spacer()

                Text(StatsService.formatHM(total))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Chart(points) {p in 
                BarMark(
                    x: .value("Day", p.day),
                    y: .value("Minutes", Double(p.seconds) / 60.0)
                )
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    if let m = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(Int(m))")
                        }
                    }
                }
            }
            .frame(height: 160)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

    }
}
