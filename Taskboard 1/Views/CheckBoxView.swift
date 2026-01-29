//
//  CheckBoxView.swift
//  Taskboard 1
//
//  Created by Jerry Joy on 2026-01-29.
//

import SwiftUI
import CoreData



struct CheckBoxView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var dateHolder: DateHolder
    @ObservedObject var passedSelectedItem: TaskItem
    
    var body: some View {
        Image(systemName: passedSelectedItem.completedDate != nil  ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(passedSelectedItem.isCompleted() ? .green : .secondary)
            .onTapGesture {
                withAnimation {
                    print("on tap gesture")
                    if !passedSelectedItem.isCompleted() {
                        passedSelectedItem.completedDate = Date()
                        dateHolder.saveContext(viewContext)
                    } else {
                        passedSelectedItem.completedDate = nil
                        dateHolder.saveContext(viewContext)
                    }
                }
            }
    }
}

#Preview {
    CheckBoxView(passedSelectedItem: TaskItem())
}
