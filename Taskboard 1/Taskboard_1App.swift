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
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
