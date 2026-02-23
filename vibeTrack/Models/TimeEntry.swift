//
//  TimeEntry.swift
//  Study
//
//  Created by MacBook on 22.12.2025.
//

import Foundation
import SwiftData

@Model
final class TimeEntry {
    @Attribute(.unique) var id: UUID

    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int

    var accumulatedSeconds: Int
    var runningSegmentStartedAt: Date?
    var isRunning: Bool

    @Relationship var discipline: Discipline?

    init(discipline: Discipline, startedAt: Date = .now) {
        self.id = UUID()
        self.startedAt = startedAt
        self.endedAt = nil
        self.durationSeconds = 0
        self.accumulatedSeconds = 0
        self.runningSegmentStartedAt = startedAt
        self.isRunning = true
        self.discipline = discipline
    }
}
