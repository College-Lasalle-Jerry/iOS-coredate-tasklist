//
//  UpdateTask.swift
//  Taskboard 1
//
//  Created by Jerry Joy on 2026-03-12.
//

import Foundation

struct UpdateTaskRequest: Codable {
    let name: String
    let desc: String
    let dueDate: Date
    let scheduleTime: Bool
    let completedDate: Date?
}
