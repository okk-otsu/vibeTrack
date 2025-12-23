//
//  BigTimerView.swift
//  Study
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI

struct BigTimerView: View {
    let seconds: Int
    let isRunning: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(format(seconds))
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()

            Text(isRunning ? "Идёт" : "Пауза / нет активной")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private func format(_ s: Int) -> String {
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return String(format: "%02d:%02d:%02d", h, m, sec)
    }
}
