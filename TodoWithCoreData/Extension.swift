//
//  Extension.swift
//  TodoWithCoreData
//
//  Created by chunwei xu on 2023/5/31.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    @discardableResult public func saveIfNeed() throws -> Bool {
        
        guard hasChanges else { return false }
        try save()
        return true
    }
}
