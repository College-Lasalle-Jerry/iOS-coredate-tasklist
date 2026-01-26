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
    

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskItem.created, ascending: true)],
        animation: .default)
    
    private var items: FetchedResults<TaskItem>
    

    var body: some View {
        NavigationView {
            VStack{

                ZStack{
                    
                    List {
                        ForEach(items) { item in
                            
                            NavigationLink(item.name ?? "", destination: TaskEditView(passedTaskItem: item, initialDate: item.created!)
                                .environmentObject(dateHolder)
                            
                            )
                            
                                                        
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
                    } // end of toolbar, end of list.
                    
                    
                    FloatingActionButton()
                        .environmentObject(dateHolder)

                }
            }
            .navigationTitle("Task Items")
        }
        
    }


    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

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
