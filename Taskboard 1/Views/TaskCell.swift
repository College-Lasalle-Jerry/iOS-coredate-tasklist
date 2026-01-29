//
//  TaskCell.swift
//  Taskboard 1
//
//  Created by Jerry Joy on 2026-01-29.
//

import SwiftUI
import CoreData

struct TaskCell: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var dateHolder: DateHolder
    
    
    @ObservedObject var passedSelectedItem: TaskItem
    var body: some View {
        HStack {
            CheckBoxView(passedSelectedItem: passedSelectedItem)
                .environmentObject(dateHolder)
            
            Text("\( passedSelectedItem.name ?? "N/A")")
            
            
            if !passedSelectedItem.isCompleted() && passedSelectedItem.scheduleTime{
                Spacer()
                Text(passedSelectedItem.dueDatetime())
                    .font(.footnote)
                    .foregroundStyle(passedSelectedItem.overDueColor())
                    .padding()
            }
        }
    }
}

#Preview {
    TaskCell(passedSelectedItem: TaskItem())
}
