//
//  EditEntryDurationSheet.swift
//  vibeTrack
//
//  Created by MacBook on 23.02.2026.
//

import SwiftUI

struct EditEntryTimeSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var startAt: Date
    @State private var endAt: Date

    init(entry: TimeEntry) {
        _startAt = State(initialValue: entry.startedAt)
        _endAt = State(initialValue: entry.endedAt ?? entry.startedAt.addingTimeInterval(TimeInterval(max(300, entry.durationSeconds))))
    }

    var body: some View {
        #if os(iOS)
        iosBody
        #else
        macBody
        #endif
    }

    // MARK: - iOS
    private var iosBody: some View {
        NavigationStack {
            Form {
                Section("Время") {
                    DatePicker("Начало", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Конец", selection: $endAt, displayedComponents: [.date, .hourAndMinute])

                    if endAt <= startAt {
                        Text("Конец должен быть позже начала")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Изменить сессию")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save() }
                        .disabled(endAt <= startAt)
                }
            }
        }
    }

    // MARK: - macOS
    private var macBody: some View {
        VStack(spacing: 18) {
            Text("Изменить сессию")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            VStack(spacing: 12) {
                HStack {
                    Text("Начало")
                    Spacer()
                    DatePicker("", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }

                HStack {
                    Text("Конец")
                    Spacer()
                    DatePicker("", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }

                if endAt <= startAt {
                    Text("Конец должен быть позже начала")
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            HStack {
                Spacer()
                Button("Отмена") { dismiss() }
                Button("Сохранить") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(endAt <= startAt)
            }
        }
        .padding(20)
        .frame(width: 360, height: 320)
    }

    private func save() {
        dismiss()
    }
}
