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
    
    init(_ context: NSManagedObjectContext) {
        // will write this later.
    }
    
    func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

}
