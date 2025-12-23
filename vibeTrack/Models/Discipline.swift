//
//  Discipline.swift
//  Study
//
//  Created by MacBook on 22.12.2025.
//

import Foundation
import SwiftData

@Model
final class Discipline {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date
    var sortOrder: Int
    @Relationship(deleteRule: .cascade, inverse: \TimeEntry.discipline)
    var entries: [TimeEntry] = []

    init(name: String, colorHex: String = "#3B82F6", sortOrder: Int = 0, createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
