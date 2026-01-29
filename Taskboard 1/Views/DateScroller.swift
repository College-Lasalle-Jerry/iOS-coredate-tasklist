//
//  DateScroller.swift
//  Taskboard 1
//
//  Created by Jerry Joy on 2026-01-29.
//

import SwiftUI

struct DateScroller: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var dateHolder: DateHolder
    
    
    var body: some View {
        HStack {
            Spacer()
            Button {
                moveBack()
            } label: {
                Image(systemName: "arrowshape.left.fill")
                    .imageScale(.large)
                    .font(Font.title.weight(.bold))
            }
            
            Text(dateFormatter())
                .font(.title)
                .bold()
                .animation(.none)
                .frame(maxWidth: .infinity)
            
            Button {
                moveForward()
            } label: {
                Image(systemName: "arrowshape.right.fill")
                    .imageScale(.large)
                    .font(Font.title.weight(.bold))
            }

        }
    }
    
    func dateFormatter() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd LLL yy"
        return dateFormatter.string(from: dateHolder.date)
    }
    
    
    func moveBack() {
        withAnimation {
            dateHolder.moveDate(days: -1, viewContext)
        }
    }
    
    func moveForward() {
        withAnimation {
            dateHolder.moveDate(days: 1, viewContext)
        }
    }
}

#Preview {
    DateScroller()
}
