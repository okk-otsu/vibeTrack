//
//  ActiveSessionView.swift
//  Study
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI
import SwiftData

struct ActiveSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var timerService: TimerService
    
    var body: some View {
        VStack(spacing: 16) {
            #if os(iOS)
            Spacer()
            #elseif os(macOS)
            #endif
            Text(timerService.activeEntry?.discipline?.name ?? "Сессия")
                .font(.title2.weight(.semibold))
            
            BigTimerView(
                seconds: timerService.currentElapsedSeconds(),
                isRunning: timerService.activeEntry != nil
            )
            
            Button(role: .destructive) {
                try? timerService.stop(modelContext: modelContext)
                dismiss() // вернуться на список
            } label: {
                Label("Стоп", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            
            #if os(iOS)
            Spacer(minLength: 300) // оптический сдвиг вверх
            #elseif os(macOS)
            Spacer(minLength: 75)
            #endif

        }
        .padding(.top, 24)
        .onReceive(timerService.$tick) { _ in } // обновление каждую секунду
        .onChange(of: timerService.activeEntry) { _, newValue in
            if newValue == nil { dismiss() }
        }
    }
}
