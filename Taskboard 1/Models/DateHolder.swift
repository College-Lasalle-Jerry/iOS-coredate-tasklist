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
    
    
    private let sync = APISync(baseURL: URL(string: "https://api.jerryjoy.me")!)
    
    
    private var isApplyingRemoteChanges = false
    
    
    init(_ context: NSManagedObjectContext) {
        // will write this later.
        refreshTaskItems(context)
        syncCurrentDay(context)
        
    }
    
    func refreshTaskItems(_ context: NSManagedObjectContext)
    {
        taskItems = fetchTaskItems(context)
    }
    
    func syncCurrentDay(_ context: NSManagedObjectContext) {
        sync.fetchTasksForDay(
            date: date,
            calendar: calendar,
            context: context
        ) { [weak self] applying in
            DispatchQueue.main.async {
                self?.isApplyingRemoteChanges = applying
            }
        } onRemoteApplied: { [weak self] in
            DispatchQueue.main.async {
                self?.refreshTaskItems(context)
            }
        }
    }
    
//    func fetchTaskItems(_ context: NSManagedObjectContext) -> [TaskItem]
//    {
//        do
//        {
//            return try context.`fetch`(dailyTasksFetch()) as [TaskItem]
//        }
//        catch let error
//        {
//            fatalError("Unresolved error \(error)")
//        }
//    }

    func fetchTaskItems(_ context: NSManagedObjectContext) -> [TaskItem] {
        do {
            let items = try context.fetch(dailyTasksFetch())

            var seen = Set<String>()
            var uniqueItems: [TaskItem] = []

            for item in items {
                guard let id = item.id?.uuidString else { continue }
                if !seen.contains(id) {
                    seen.insert(id)
                    uniqueItems.append(item)
                }
            }

            print("LOCAL TASK COUNT AFTER FETCH:", uniqueItems.count)
            for item in uniqueItems {
                print("LOCAL:", item.id?.uuidString ?? "nil", item.name ?? "", item.dueDate ?? Date())
            }

            return uniqueItems
        } catch {
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
        
//        sync.fetchTasksForDay(
//            date: date,
//            calendar: calendar,
//            context: context
//        ) { [weak self] applying in
//            self?.isApplyingRemoteChanges = applying
//        } onRemoteApplied: { [weak self] in
//            self?.refreshTaskItems(context)
//        }
        
        syncCurrentDay(context)
        
        refreshTaskItems(context)
    }
    
    
    
    // func -- check the ID is correct/stable
    private func ensureStableIDs(_ context: NSManagedObjectContext){
        for obj in context.insertedObjects {
            guard let t = obj as? TaskItem else { continue }
            if t.id == nil { t.id = UUID() }
            if t.created == nil { t.created = Date() }
        }
    }
    
//    func saveContext(_ context: NSManagedObjectContext) {
//        
//        ensureStableIDs(context)
//        
//        let inserted = context.insertedObjects.compactMap { $0 as? TaskItem }
//        let updated  = context.updatedObjects.compactMap { $0 as? TaskItem }
//        let deleted  = context.deletedObjects.compactMap { $0 as? TaskItem }
//        
//        let deletedIDs: [UUID] = deleted.compactMap { $0.id }
//        
//        print("---- saveContext ----")
//        print("inserted:", inserted.map { $0.id?.uuidString ?? "nil" })
//        print("updated :", updated.map { $0.id?.uuidString ?? "nil" })
//        print("deleted :", deletedIDs.map(\.uuidString))
//        print("isApplyingRemoteChanges:", isApplyingRemoteChanges)
//        
//        print("UPDATED IDS:", updated.map { $0.id?.uuidString ?? "nil" })
//        for item in updated {
//            print("UPDATED completedDate:", item.completedDate as Any)
//        }
//        
//        do {
//            try context.save()
//            refreshTaskItems(context) // always refresh
//            
//            deletedIDs.forEach {
//                print("API DELETE:", $0.uuidString)
//                sync.pushDelete(taskID: $0)
//            }
//            
//            guard !isApplyingRemoteChanges else {
//                print("Skipping create/update because isApplyingRemoteChanges = true")
//                return
//            }
//            
//            inserted.forEach {
//                print("API CREATE:", $0.id?.uuidString ?? "nil")
//                sync.pushCreate(task: $0)
//            }
//            
//            updated.forEach {
//                print("API UPDATE:", $0.id?.uuidString ?? "nil")
//                sync.pushUpdate(task: $0)
//            }
//        } catch {
//            // Replace this implementation with code to handle the error appropriately.
//            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            let nsError = error as NSError
//            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//        }
//    }
    
    
    func saveContext(_ context: NSManagedObjectContext) {
        ensureStableIDs(context)

        let inserted = context.insertedObjects.compactMap { $0 as? TaskItem }
        let updated  = context.updatedObjects.compactMap { $0 as? TaskItem }
        let deleted  = context.deletedObjects.compactMap { $0 as? TaskItem }

        let deletedIDs: [UUID] = deleted.compactMap { $0.id }

        print("---- saveContext ----")
        print("inserted:", inserted.map { $0.id?.uuidString ?? "nil" })
        print("updated :", updated.map { $0.id?.uuidString ?? "nil" })
        print("deleted :", deletedIDs.map(\.uuidString))
        print("isApplyingRemoteChanges:", isApplyingRemoteChanges)

        for item in updated {
            print("UPDATED TASK -> id:", item.id?.uuidString ?? "nil")
            print("name:", item.name ?? "")
            print("dueDate:", item.dueDate as Any)
            print("completedDate:", item.completedDate as Any)
        }

        do {
            try context.save()
            refreshTaskItems(context)

            deletedIDs.forEach {
                print("API DELETE:", $0.uuidString)
                sync.pushDelete(taskID: $0)
//                {
//                    [weak self] in
//                    self?.syncCurrentDay(context)
//                }
            }

            guard !isApplyingRemoteChanges else {
                print("Skipping create/update because isApplyingRemoteChanges = true")
                return
            }

            inserted.forEach {
                print("API CREATE:", $0.id?.uuidString ?? "nil")
                sync.pushCreate(task: $0)
            }

            updated.forEach {
                print("API UPDATE:", $0.id?.uuidString ?? "nil")
                sync.pushUpdate(task: $0)
//                {
//                    [weak self] in
//                    DispatchQueue.main.async {
//                        self?.syncCurrentDay(context)
//                    }
//                }
            }
            
            

        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
}
