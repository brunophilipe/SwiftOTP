//
//  NSManagedObject+Helpers.swift
//  Journal
//
//  Created by Bruno Philipe on 3/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import CoreData

extension NSManagedObject
{
	static func makeFetchedResultsController<T: NSManagedObject>(context: NSManagedObjectContext,
																 sortDescriptors: [NSSortDescriptor] = [],
																 cacheName: String? = nil,
																 predicate: String,
																 _ values: [String: Any]? = nil) -> NSFetchedResultsController<T>
	{
		var predicate = NSPredicate(format: predicate)

		if let values = values
		{
			predicate = predicate.withSubstitutionVariables(values)
		}

		return makeFetchedResultsController(context: context,
											sortDescriptors: sortDescriptors,
											cacheName: cacheName,
											predicate: predicate)
	}

	static func makeFetchedResultsController<T: NSManagedObject>(context: NSManagedObjectContext,
																 sortDescriptors: [NSSortDescriptor] = [],
																 cacheName: String? = nil,
																 predicate: NSPredicate? = nil) -> NSFetchedResultsController<T>
	{
		let fetchedResultsController: NSFetchedResultsController<T>
		let fetchRequest: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>

		// Set the batch size to a suitable number.
		fetchRequest.fetchBatchSize = 20

		// Edit the sort key as appropriate.
		fetchRequest.sortDescriptors = sortDescriptors

		// Set the predicate
		fetchRequest.predicate = predicate

		// Edit the section name key path and cache name if appropriate.
		// nil for section name key path means "no sections".
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
															  managedObjectContext: context,
															  sectionNameKeyPath: nil,
															  cacheName: cacheName)
		do
		{
			try fetchedResultsController.performFetch()
		}
		catch
		{
			// Replace this implementation with code to handle the error appropriately.
			// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}

		return fetchedResultsController
	}
}
