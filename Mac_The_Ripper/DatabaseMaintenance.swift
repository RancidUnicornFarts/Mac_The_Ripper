//
//  DatabaseMaintenance.swift
//  Mac_The_Ripper
//
//  Created by Fredd Dagg on 27.01.2026.
//

import Foundation
import CoreData

enum DatabaseMaintenance {

    /// Deletes all Title and Disk records using batch deletes.
    /// Call on the main thread (it merges changes back into the viewContext).
    static func clearAll(container: NSPersistentContainer) throws {
        let context = container.viewContext

        // Batch delete Titles first, then Disks (safe even if cascade exists)
        try batchDelete(entityName: "Title", in: context)
        try batchDelete(entityName: "Disk", in: context)

        // Ensure in-memory objects are reset/consistent
        context.reset()
    }

    private static func batchDelete(entityName: String, in context: NSManagedObjectContext) throws {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        request.resultType = .resultTypeObjectIDs

        let result = try context.execute(request) as? NSBatchDeleteResult
        let objectIDs = (result?.result as? [NSManagedObjectID]) ?? []

        // Merge so FetchRequests update immediately
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
    }
}
