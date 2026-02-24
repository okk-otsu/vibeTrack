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
    var durationSeconds: Int {
        guard let endedAt else { return 0 }
        return max(0, Int(endedAt.timeIntervalSince(startedAt)))
    }
    
    var effectiveSeconds: Int {
        if let endedAt {
            return max(0, Int(endedAt.timeIntervalSince(startedAt)))
        }
        let running = runningSegmentStartedAt.map { Int(Date.now.timeIntervalSince($0)) } ?? 0
        return max(0, accumulatedSeconds + running)
    }
    
    var accumulatedSeconds: Int
    var runningSegmentStartedAt: Date?
    var isRunning: Bool
    
    @Relationship var discipline: Discipline?

    init(discipline: Discipline, startedAt: Date = .now) {
        self.id = UUID()
        self.startedAt = startedAt
        self.endedAt = nil
        self.accumulatedSeconds = 0
        self.runningSegmentStartedAt = startedAt
        self.isRunning = true
        self.discipline = discipline
    }
    
}

