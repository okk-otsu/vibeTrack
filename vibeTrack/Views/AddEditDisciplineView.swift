//
//  AddEditDisciplineView.swift
//  Study
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI
import SwiftData

struct AddEditDisciplineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // если nil — создаём, если не nil — редактируем
    private let disciplineToEdit: Discipline?

    @State private var name: String
    @State private var colorHex: String
    @State private var showDuplicateAlert = false

    // 30 цветов (hex), ты можешь подправить какие нравятся
    private let palette: [String] = [
        // Blue
        "#3B82F6", "#2563EB", "#60A5FA",

        // Orange
        "#F97316", "#FB923C", "#EA580C",

        // Red
        "#EF4444", "#DC2626", "#F87171",

        // Yellow
        "#FACC15", "#EAB308", "#FDE047",

        // Green
        "#22C55E", "#16A34A", "#4ADE80",

        // Teal / Cyan
        "#14B8A6", "#06B6D4", "#67E8F9",

        // Purple
        "#8B5CF6", "#A855F7", "#C084FC",

        // Pink
        "#EC4899", "#F43F5E", "#FDA4AF",

        // Neutral / Gray
        "#64748B", "#475569", "#9CA3AF"
    ]

    init(disciplineToEdit: Discipline? = nil) {
        self.disciplineToEdit = disciplineToEdit
        _name = State(initialValue: disciplineToEdit?.name ?? "")
        _colorHex = State(initialValue: disciplineToEdit?.colorHex ?? "#3B82F6")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например: Матан", text: $name)
                    #if os(iOS)
                        .textInputAutocapitalization(.words)
                    #endif
                }

                Section("Цвет") {
                    ColorPickerGrid(
                        palette: palette,
                        selectedHex: $colorHex
                    )
                }
            }
            .navigationTitle(disciplineToEdit == nil ? "Новая дисциплина" : "Редактировать")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Такая дисциплина уже существует", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Выбери другое имя.")
            }
        }
    }

    // MARK: - Save

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Проверка на дубликаты (регистрозависимо, как ты хотел):
        // "матан" и "Матан" считаем разными
        if isDuplicateName(trimmed) {
            showDuplicateAlert = true
            return
        }

        if let d = disciplineToEdit {
            // edit
            d.name = trimmed
            d.colorHex = colorHex
        } else {
            // create
            let nextOrder = (try? modelContext.fetch(FetchDescriptor<Discipline>()).count) ?? 0
            let d = Discipline(name: trimmed, colorHex: colorHex, sortOrder: nextOrder)
            modelContext.insert(d)
        }

        try? modelContext.save()
        dismiss()
    }

    private func isDuplicateName(_ newName: String) -> Bool {
        let all = (try? modelContext.fetch(FetchDescriptor<Discipline>())) ?? []
        if let editing = disciplineToEdit {
            // при редактировании игнорируем текущую дисциплину
            return all.contains { $0.id != editing.id && $0.name == newName }
        } else {
            return all.contains { $0.name == newName }
        }
    }
}
