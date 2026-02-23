//
//  DisciplineListView.swift
//  Study
//
//  Created by MacBook on 22.12.2025.
//

import SwiftUI
import SwiftData

struct DisciplineListView: View {
    @State private var goToActive = false
    
    @State private var editingDiscipline: Discipline?
    
    @State private var selectedForDelete: Discipline?
    @State private var showDeleteConfirm = false
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var timerService: TimerService
    #if os(iOS)
    @Environment(\.editMode) private var editMode
    #endif
    @Query(sort: \Discipline.sortOrder, order: .forward)
    private var disciplines: [Discipline]
    
    private enum Route: Hashable {
        case active
    }

    @State private var path = NavigationPath()

    @State private var showAdd = false
    
    private var activeEntry: TimeEntry? { timerService.activeEntry }
    private var hasActive: Bool { activeEntry != nil }

    private var todayTotal: Int {
        StatsService.todayTotalSeconds(
            modelContext: modelContext,
            activeEntry: activeEntry
        )
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {
                headerView
                listView
            }
            .toolbar { toolbarContent }
            .sheet(isPresented: $showAdd) { AddEditDisciplineView() }
            .sheet(item: $editingDiscipline) { d in
                AddEditDisciplineView(disciplineToEdit: d)
            }
            .alert("Удалить дисциплину?", isPresented: $showDeleteConfirm) {
                Button("Удалить", role: .destructive) {
                    if let d = selectedForDelete {
                        modelContext.delete(d)
                        try? modelContext.save()
                    }
                    selectedForDelete = nil
                }
                Button("Отмена", role: .cancel) {
                    selectedForDelete = nil
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .active:
                    ActiveSessionView()
                }
            }
        }
        .onReceive(timerService.$tick) { _ in }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            BigTimerView(
                seconds: todayTotal,
                isRunning: hasActive
            )

            if hasActive {
                Button(role: .destructive) {
                    try? timerService.stop(modelContext: modelContext)
                } label: {
                    Label("Стоп", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    private var listView: some View {
        List {
            Section("Дисциплины") {
                ForEach(disciplines) { d in
                    row(for: d)
                }
                .onMove(perform: move)
            }
        }
    #if os(iOS)
        .listStyle(.plain)
    #endif
    }
    
    @ViewBuilder
    private func row(for d: Discipline) -> some View {
        let isActive = activeEntry?.discipline?.id == d.id

        DisciplineRow(
            discipline: d,
            isActive: isActive,
            canStart: !hasActive,
            activeEntry: activeEntry,
            onStart: {
                guard !hasActive else { return }
                try? timerService.start(discipline: d, modelContext: modelContext)
                DispatchQueue.main.async {
                        path.append(Route.active)
                    }
            },
            onEdit: {
                editingDiscipline = d
            },
            onDelete: {
                selectedForDelete = d
                showDeleteConfirm = true
            }
        )
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
    #if os(iOS)
        ToolbarItem(placement: .topBarTrailing) { EditButton() }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showAdd = true } label: { Image(systemName: "plus") }
        }
    #elseif os(macOS)
        ToolbarItem(placement: .automatic) {
            Button { showAdd = true } label: { Image(systemName: "plus") }
        }
    #endif
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        var updated = disciplines
        updated.move(fromOffsets: source, toOffset: destination)

        for (idx, d) in updated.enumerated() {
            d.sortOrder = idx
        }
        try? modelContext.save()
    }

}

extension StatsService {
    static func todayTotalSeconds(
        modelContext: ModelContext,
        activeEntry: TimeEntry?
    ) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let end = cal.date(byAdding: .day, value: 1, to: start)!

        let fd = FetchDescriptor<TimeEntry>(
            predicate: #Predicate { e in
                e.endedAt != nil && e.startedAt >= start && e.startedAt < end
            }
        )
        let finished = (try? modelContext.fetch(fd)) ?? []
        var total = finished.reduce(0) { $0 + $1.durationSeconds }

        if let activeEntry,
           activeEntry.startedAt >= start && activeEntry.startedAt < end {
            total += max(0, Int(Date.now.timeIntervalSince(activeEntry.startedAt)))
        }

        return total
    }
}
