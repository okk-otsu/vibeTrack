////
////  DonutBreakdownView.swift
////  vibeTrack
////
////  Created by MacBook on 22.12.2025.
////
//
//import SwiftUI
//import Charts
//
//struct DonutBreakdownView: View {
//    let slices: [DisciplineSlice]
//    let totalSeconds: Int
//
//    var body: some View {
//        HStack(spacing: 16) {
//            Chart(slices) { s in
//                SectorMark(
//                    angle: .value("Seconds", s.seconds),
//                    innerRadius: .ratio(0.60)
//                )
//                .foregroundStyle(Color(hex: s.discipline.colorHex))
//            }
//            .frame(width: 170, height: 170)
//            .chartLegend(.hidden)
//
//            VStack(alignment: .leading, spacing: 10) {
//                ForEach(slices) { s in
//                    HStack(spacing: 10) {
//                        RoundedRectangle(cornerRadius: 3)
//                            .fill(Color(hex: s.discipline.colorHex))
//                            .frame(width: 6, height: 18)
//
//                        Text(s.discipline.name)
//                            .lineLimit(1)
//
//                        Spacer()
//
//                        let pct = totalSeconds == 0 ? 0 : Int((Double(s.seconds) / Double(totalSeconds)) * 100.0)
//                        Text("\(StatsService.formatHM(s.seconds)) · \(pct)%")
//                            .foregroundStyle(.secondary)
//                            .monospacedDigit()
//                    }
//                }
//            }
//            .font(.callout)
//        }
//        .padding()
//        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
//    }
//}
