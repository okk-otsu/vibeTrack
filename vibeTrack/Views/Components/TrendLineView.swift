//
//  TrendLineView.swift
//  vibeTrack
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI
import Charts

struct TrendLineView: View {
    let points: [StatsService.DayPoint]

    var body: some View {
        let total = points.reduce(0) { $0 + $1.seconds }

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trend")
                    .font(.headline)
                Spacer()
                Text(StatsService.formatHM(total))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Chart(points) { p in
                LineMark(
                    x: .value("Day", p.day),
                    y: .value("Seconds", p.seconds)
                )
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Day", p.day),
                    y: .value("Seconds", p.seconds)
                )
                .opacity(0.12)
            }
            .frame(height: 160)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
