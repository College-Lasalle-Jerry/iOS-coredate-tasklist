//
//  TaskItemDTO.swift
//  Taskboard 1
//
//  Created by Jerry Joy on 2026-03-12.
//

import Foundation

struct TaskDTO: Codable, Identifiable {
    let id: String
    let name: String
    let desc: String
    let dueDate: Date
    let created: Date
    let scheduleTime: Bool
    let completedDate: Date?
}
