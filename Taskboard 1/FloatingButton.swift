//
//  FloatingButton.swift
//  Taskboard 1
//
//  Created by Jerry Joy on 2026-01-21.
//

import SwiftUI

struct FloatingActionButton: View {
    
    @EnvironmentObject var dateHolder: DateHolder
    
    
    var body: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                HStack{
                    // navigation link to the task edit/create screen
                    NavigationLink(
                        destination: TaskEditView(passedTaskItem: nil, initialDate: Date())
                            .environmentObject(dateHolder)
                    ) {
                        Text("New Task")
                            .font(.title2)
                            .padding()
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
}


#Preview {
    FloatingActionButton()
}
