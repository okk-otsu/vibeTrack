//
//  MostUsedListView.swift
//  vibeTrack
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI

struct MostUsedListView: View {
    @State private var expanded = false
    
    let title: String
    let rows: [StatsService.TopDisciplineRow]
    let limit: Int = 7
    private var shown: [StatsService.TopDisciplineRow] {
        expanded ? rows : Array(rows.prefix(limit))
    }
    private var maxSec: Int { shown.first?.seconds ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text(title.uppercased())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            VStack(spacing: 0) {
                ForEach(shown) { r in
                    MostUsedRow(
                        name: r.name,
                        colorHex: r.colorHex,
                        seconds: r.seconds,
                        maxSeconds: maxSec
                    )
                    Divider().opacity(0.35)
                }

                if rows.count > limit {
                    Button {
                        withAnimation(.snappy) { expanded.toggle() }
                    } label: {
                        Text(expanded ? "Show Less" : "Show More")
                            .foregroundStyle(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct MostUsedRow: View {
    let name: String
    let colorHex: String
    let seconds: Int
    let maxSeconds: Int

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(name)
                        .font(.body)
                    Spacer()
                    Text(pretty(seconds))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                GeometryReader { geo in
                    let w = geo.size.width
                    let ratio = CGFloat(seconds) / CGFloat(max(maxSeconds, 1))
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.18))
                        Capsule().fill(Color.secondary.opacity(0.45))
                            .frame(width: max(6, w * ratio))
                    }
                }
                .frame(height: 6)
            }

        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }

    private func pretty(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
