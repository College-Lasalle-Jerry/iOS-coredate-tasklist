//
//  ContentView.swift
//  Taskboard 1
//
//  Created by Jerry Joy on 2026-01-21.
//

import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // context for the save
    @EnvironmentObject var dateHolder: DateHolder
    
    
    //    @FetchRequest(
    //        sortDescriptors: [NSSortDescriptor(keyPath: \TaskItem.created, ascending: true)],
    //        animation: .default)
    //
    //    private var items: FetchedResults<TaskItem>
    
    @State var selectedFilter = TaskFilter.NonCompleted
    
    var body: some View {
        NavigationView {
            VStack{
                DateScroller()
                    .padding( )
                    .environmentObject(dateHolder)
                
                ZStack{
                    
                    List {
                        ForEach(filteredTaskItems()) { item in
                            
                            
                            NavigationLink(
                                destination:
                                    TaskEditView(passedTaskItem: item, initialDate: item.created!)
                                    .environmentObject(dateHolder)
                            ) {
                                TaskCell(passedSelectedItem: item)
                                    .environmentObject(dateHolder)
                            }
                            
                            
                            
                            
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            //                            EditButton()
                            
                            Picker("", selection: $selectedFilter.animation())
                            {
                                ForEach(TaskFilter.allFilters, id: \.self)
                                {
                                    filter in
                                    Text(filter.rawValue)
                                }
                            }
                        }
                    } // end of toolbar, end of list.
                    
                    
                    FloatingActionButton()
                        .environmentObject(dateHolder)
                    
                }
            }
            .navigationTitle("Task Items")
        }
        
    }
    
    private func filteredTaskItems() -> [TaskItem]
    {
        if selectedFilter == TaskFilter.Completed
        {
            return dateHolder.taskItems.filter{ $0.isCompleted()}
        }
        
        if selectedFilter == TaskFilter.NonCompleted
        {
            return dateHolder.taskItems.filter{ !$0.isCompleted()}
        }
        
        if selectedFilter == TaskFilter.OverDue
        {
            return dateHolder.taskItems.filter{ $0.isOverdue()}
        }
        
        return dateHolder.taskItems
    }
    
    
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { dateHolder.taskItems[$0] }.forEach(viewContext.delete)
            
            dateHolder.saveContext(viewContext)
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    TaskListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
