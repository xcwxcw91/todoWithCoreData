//
//  ToDoItem+CoreDataProperties.swift
//  TodoWithCoreData
//
//  Created by chunwei xu on 2023/5/31.
//
//

import Foundation
import CoreData


extension ToDoItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ToDoItem> {
        return NSFetchRequest<ToDoItem>(entityName: "ToDoItem")
    }

    @NSManaged public var name: String?
    @NSManaged public var identifier: String?
    @NSManaged public var colorflag: Int16
    @NSManaged public var order: Int16
 
    // make auto set value to identifier
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        
        setPrimitiveValue(UUID().uuidString, forKey: #keyPath(ToDoItem.identifier))
    }
}

extension ToDoItem : Identifiable {

}
