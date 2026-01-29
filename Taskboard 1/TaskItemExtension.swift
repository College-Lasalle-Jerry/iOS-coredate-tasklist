//
//  TaskItemExtension.swift
//  Taskboard 1
//
//  Created by Jerry Joy on 2026-01-29.
//

import SwiftUI


extension TaskItem {
    
    func isCompleted() -> Bool {
        print("is completed")
        print(completedDate != nil)
        return completedDate != nil
    }
    
    func isOverdue() -> Bool {
        if let due = dueDate {
            return !isCompleted() && scheduleTime && due < Date()
        }
        
        return false
    }
    
    func overDueColor() -> Color {
        return isOverdue() ? Color.red : Color.primary
    }
    
    
    func dueDatetime() -> String {
        if let due = dueDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm a"
            return dateFormatter.string(from: due)
        }
        
        return ""
    }
}
