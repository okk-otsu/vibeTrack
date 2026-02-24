//
//  AddManualSessionSheet.swift
//  vibeTrack
//
//  Created by MacBook on 24.02.2026.
//

import SwiftUI
import SwiftData

struct AddManualSessionSheet: View {
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Discipline.sortOrder, order: .forward)
    private var disciplineList: [Discipline]

    @Query(sort: \TimeEntry.startedAt, order: .forward)
    private var allEntries: [TimeEntry]

    @State private var selectedDiscipline: Discipline?
    @State private var startAt: Date
    @State private var endAt: Date

    @State private var errorText: String?
    @State private var showOverlapAlert = false
    @State private var overlapMessage = ""

    init(date: Date) {
        self.date = date
        let cal = Calendar.current
        let base = cal.startOfDay(for: date)
        _startAt = State(initialValue: cal.date(byAdding: .hour, value: 10, to: base) ?? date)
        _endAt   = State(initialValue: cal.date(byAdding: .hour, value: 11, to: base) ?? date)
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
                disciplineSection
                timeSection
                errorSectionIfNeeded
            }
            .navigationTitle("Добавить сессию")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save() }
                        .disabled(!canSave)
                }
            }
            .alert("Пересечение сессий", isPresented: $showOverlapAlert) {
                Button("Ок", role: .cancel) { }
            } message: {
                Text(overlapMessage)
            }
        }
    }

    // MARK: - macOS
    private var macBody: some View {
        VStack(spacing: 18) {
            Text("Добавить сессию")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 14) {
                HStack {
                    Text("Дисциплина")
                    Spacer()
                }
                HStack {
                    Text("Выбрать")
                        .foregroundStyle(.secondary)
                    Picker("", selection: $selectedDiscipline) {
                        Text("—").tag(nil as Discipline?)
                        ForEach(disciplineList, id: \.id) { d in
                            Text(d.name).tag(Optional(d))
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 220)
                }

                Divider().opacity(0.25)

                HStack {
                    Text("Начало")
                    Spacer()
                    DatePicker("", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ru_RU"))
                    
                }

                HStack {
                    Text("Конец")
                    Spacer()
                    DatePicker("", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ru_RU"))

                }

                if endAt <= startAt {
                    Text("Конец должен быть позже начала")
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let errorText {
                    Text(errorText)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Spacer()

            HStack {
                Spacer()
                Button("Отмена") { dismiss() }
                Button("Сохранить") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
        }
        .padding(20)
        .frame(width: 360, height: 320) 
        .alert("Пересечение сессий", isPresented: $showOverlapAlert) {
            Button("Ок", role: .cancel) { }
        } message: {
            Text(overlapMessage)
        }
        .onChange(of: startAt) { _, _ in
            if endAt <= startAt { endAt = startAt.addingTimeInterval(5 * 60) }
            errorText = nil
        }
        .onChange(of: endAt) { _, _ in
            errorText = (endAt <= startAt) ? "Конец должен быть позже начала." : nil
        }
    }

    // MARK: - Sections (shared)
    private var disciplineSection: some View {
        Section("Дисциплина") {
            Picker("Выбрать", selection: $selectedDiscipline) {
                Text("—").tag(nil as Discipline?)
                ForEach(disciplineList, id: \.id) { d in
                    Text(d.name).tag(Optional(d))
                }
            }
        }
    }

    private var timeSection: some View {
        Section("Время") {
            DatePicker("Начало", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
            DatePicker("Конец", selection: $endAt, displayedComponents: [.date, .hourAndMinute])

            if endAt <= startAt {
                Text("Конец должен быть позже начала")
                    .foregroundStyle(.red)
            }
        }
        .onChange(of: startAt) { _, _ in
            if endAt <= startAt { endAt = startAt.addingTimeInterval(5 * 60) }
            errorText = nil
        }
        .onChange(of: endAt) { _, _ in
            errorText = (endAt <= startAt) ? "Конец должен быть позже начала." : nil
        }
    }

    private var errorSectionIfNeeded: some View {
        Group {
            if let errorText {
                Section {
                    Text(errorText).foregroundStyle(.red)
                }
            }
        }
    }

    private var canSave: Bool {
        selectedDiscipline != nil && endAt > startAt
    }

    // MARK: - Save logic
    private func save() {
        guard let discipline = selectedDiscipline else { return }
        guard endAt > startAt else {
            errorText = "Конец должен быть позже начала."
            return
        }

        if let conflict = findOverlap(start: startAt, end: endAt) {
            overlapMessage = conflict
            showOverlapAlert = true
            return
        }

        let entry = TimeEntry(discipline: discipline, startedAt: startAt)
        entry.endedAt = endAt

        let duration = max(0, Int(endAt.timeIntervalSince(startAt)))
        entry.durationSeconds = duration
        entry.accumulatedSeconds = duration
        entry.runningSegmentStartedAt = nil
        entry.isRunning = false

        modelContext.insert(entry)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorText = "Не удалось сохранить: \(error.localizedDescription)"
        }
    }

    private func findOverlap(start: Date, end: Date) -> String? {
        let now = Date()

        for e in allEntries {
            let c = e.startedAt
            let d: Date
            if let endedAt = e.endedAt {
                d = endedAt
            } else if e.isRunning {
                d = now
            } else {
                d = e.startedAt.addingTimeInterval(TimeInterval(max(0, e.durationSeconds)))
            }

            if start < d && c < end {
                let f = DateFormatter()
                f.dateFormat = "dd.MM.yyyy, HH:mm"
                let left = "\(f.string(from: c)) – \(f.string(from: d))"
                let name = e.discipline?.name ?? "Без дисциплины"
                return "Конфликт с сессией: \(name) (\(left))"
            }
        }

        return nil
    }
}
