//
//  Persistence.swift
//  TodoWithCoreData
//
//  Created by chunwei xu on 2023/5/31.
//

import CoreData

struct PersistenceController {
    static var shared = PersistenceController()

    var container: NSPersistentContainer

    init(inMemory: Bool = false) {
        
        container = NSPersistentContainer(name: "TodoWithCoreData")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
     
    // destroy and reset coreData -- caution to use this method
    public mutating func deleteAllAndResetCoreData() async{
        
        let storeCoordinator = container.persistentStoreCoordinator
        
        // let storeCoordinator delete all existing persistent stores
        for store in storeCoordinator.persistentStores {
            
            do {
                try storeCoordinator.destroyPersistentStore(at: store.url!, ofType: store.type, options: nil)
            }
            catch {
                
            }
        }
        
        //recreate cantainer
        container = NSPersistentContainer(name: "TodoWithCoreData")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
}
