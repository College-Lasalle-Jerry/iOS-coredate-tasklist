//
//  DateHolder.swift
//  Taskboard 1
//
//  Created by Jerry Joy on 2026-01-22.
//

import SwiftUI
import CoreData
import Combine

class DateHolder: ObservableObject {
    
    @Published var date: Date = Date()
    @Published var taskItems: [TaskItem] = []
    
    let calendar: Calendar = Calendar.current
    
    
    
    init(_ context: NSManagedObjectContext) {
        // will write this later.
        refreshTaskItems(context)
    }
    
    func refreshTaskItems(_ context: NSManagedObjectContext)
    {
        taskItems = fetchTaskItems(context)
    }
    
    func fetchTaskItems(_ context: NSManagedObjectContext) -> [TaskItem]
    {
        do
        {
            return try context.fetch(dailyTasksFetch()) as [TaskItem]
        }
        catch let error
        {
            fatalError("Unresolved error \(error)")
        }
    }
    
    func dailyTasksFetch() -> NSFetchRequest<TaskItem>
    {
        let request = TaskItem.fetchRequest()
        
        request.sortDescriptors = sortOrder()
        request.predicate = predicate()
        return request
    }
    
    private func sortOrder() -> [NSSortDescriptor]
    {
        let completedDateSort = NSSortDescriptor(keyPath: \TaskItem.completedDate, ascending: true)
        let timeSort = NSSortDescriptor(keyPath: \TaskItem.scheduleTime, ascending: true)
        let dueDateSort = NSSortDescriptor(keyPath: \TaskItem.dueDate, ascending: true)
        
        return [completedDateSort, timeSort, dueDateSort]
    }
    
    private func predicate() -> NSPredicate
    {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)
        return NSPredicate(format: "dueDate >= %@ AND dueDate < %@", start as NSDate, end! as NSDate)
    }
    
    
    func moveDate(days: Int, _ context: NSManagedObjectContext){
        date = calendar.date(byAdding: .day, value: days, to: date)!
        refreshTaskItems(context)
    }
    
    func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
            refreshTaskItems(context) // always refresh 
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

}
