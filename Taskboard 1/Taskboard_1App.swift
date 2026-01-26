//
//  Taskboard_1App.swift
//  Taskboard 1
//
//  Created by Jerry Joy on 2026-01-21.
//

import SwiftUI
import CoreData

@main
struct Taskboard_1App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            let context = persistenceController.container.viewContext
            let dateHolder = DateHolder(context)
            TaskListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext )
                .environmentObject(dateHolder)
        }
    }
}
