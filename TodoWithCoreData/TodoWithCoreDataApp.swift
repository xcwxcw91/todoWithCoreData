//
//  TodoWithCoreDataApp.swift
//  TodoWithCoreData
//
//  Created by chunwei xu on 2023/5/31.
//

import SwiftUI

@main
struct TodoWithCoreDataApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ToDoList()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
