//
//  TaskEditView.swift
//  Taskboard 1
//
//  Created by Jerry Joy on 2026-01-21.
//

import SwiftUI
import CoreData

struct TaskEditView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var dateHolder: DateHolder
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    
    @State private var name: String
    @State private var desc: String
    @State private var dueDate: Date
    @State private var scheduleTime: Bool
    
    
    @State private var selectedTaskItem: TaskItem?
    
    init(passedTaskItem: TaskItem? = nil, initialDate: Date) {
        if let taskItem = passedTaskItem {
            _selectedTaskItem = State(initialValue: taskItem)
            _name = State(initialValue: taskItem.name ?? "")
            _desc = State(initialValue: taskItem.desc ?? "")
            _dueDate = State(initialValue: taskItem.dueDate ?? initialDate)
            _scheduleTime = State(initialValue: taskItem.scheduleTime ?? false)

        }else {
            _selectedTaskItem = State(initialValue: nil)
            _name = State(initialValue: "")
            _desc = State(initialValue: "")
            _dueDate = State(initialValue: initialDate)
            _scheduleTime = State(initialValue: false)
        }

    }
    
    var body: some View {
        Form {
            Section(header: Text("Task")) {
                TextField("Task name", text: $name)
                TextField("Description", text: $desc)
                
            }
            
            
            Section(header: Text("Due Date")) {
                Toggle("Schedule Time", isOn: $scheduleTime)
                DatePicker("Due Date", selection: $dueDate, displayedComponents: displayComps())
                
            }
            
            
            if selectedTaskItem?.isCompleted() ?? false {
                Section(header: Text("Completed")) {
                    Text(
                        selectedTaskItem?.completedDate?.formatted(
                            date: .abbreviated,
                            time: .shortened
                        ) ?? ""
                    )
                    .foregroundStyle(.green)
                }
            }
            
            Section {
                Button(action: saveAction) {
                    Text("Save")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    func displayComps() -> DatePickerComponents {
        return scheduleTime ? [.date, .hourAndMinute] : [.date]
    }
    
    // save button functionality.
    
    func saveAction() {
        withAnimation {
            if selectedTaskItem == nil {
                let newItem = TaskItem(context: viewContext)
                newItem.created = Date()
                selectedTaskItem = newItem
            }
            selectedTaskItem?.id = UUID()
            selectedTaskItem?.created = Date()
            selectedTaskItem?.name = name
            selectedTaskItem?.desc = desc
            selectedTaskItem?.dueDate = dueDate
            selectedTaskItem?.scheduleTime = scheduleTime
            
            dateHolder.saveContext(viewContext)
            
            // dismiss
            presentationMode.wrappedValue.dismiss() // this will dismiss the screen
            
        }
    }
}

#Preview {
    TaskEditView(
        passedTaskItem: TaskItem(),
        initialDate: Date()
    )
}
