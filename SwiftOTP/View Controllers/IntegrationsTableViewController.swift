//
//  IntegrationsTableViewController.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 7/28/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit
import OTPKit
import CoreData
import WebKit

class IntegrationsTableViewController: UITableViewController
{
	private lazy var fetchedResultsController: NSFetchedResultsController<Integration> =
	{
		let sortDescriptors = [NSSortDescriptor(key: "appName", ascending: false)]
		let managedObjectContext = AppDelegate.shared.managedObjectContext
		let controller: NSFetchedResultsController<Integration>
		controller = Integration.makeFetchedResultsController(context: managedObjectContext,
															  sortDescriptors: sortDescriptors)
		controller.delegate = self
		return controller
	}()

	private weak var tokenStore: TokenStore? = AppDelegate.shared.tokenStore

	@IBAction private func showDocs(_ sender: Any?)
	{
		guard
			let docsWrapperUrl = Bundle.main.url(forResource: "DocsWrapper", withExtension: "html"),
			let docsContentUrl = Bundle.main.url(forResource: "SwiftOTP", withExtension: "html"),
			let docsContent = try? String(contentsOf: docsContentUrl),
			let docsWrapper = try? String(contentsOf: docsWrapperUrl).replacingOccurrences(of: "##CONTENT##", with: docsContent)
		else
		{
			return
		}

		let webView = WKWebView()
		let viewController = UIViewController()
		viewController.view = webView

		show(viewController, sender: sender)

		webView.loadHTMLString(docsWrapper, baseURL: nil)
	}

	// MARK: - Table View

	override func numberOfSections(in tableView: UITableView) -> Int
	{
		return fetchedResultsController.sections?.count ?? 0
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		let sectionInfo = fetchedResultsController.sections![section]
		return sectionInfo.numberOfObjects
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "IntegrationCell", for: indexPath)
		let event = fetchedResultsController.object(at: indexPath)
		configureCell(cell, withIntegration: event)
		return cell
	}

	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
	{
		// Return false if you do not want the specified item to be editable.
		return true
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
	{
		if editingStyle == .delete
		{
			let context = fetchedResultsController.managedObjectContext
			context.delete(fetchedResultsController.object(at: indexPath))

			do
			{
				try context.save()
			}
			catch
			{
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}

	override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String?
	{
		return "Revoke"
	}

	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String?
	{
		guard section == 0 else
		{
			return nil
		}

		if fetchedResultsController.sections![section].numberOfObjects == 0
		{
			return "Apps that were authorized to fetch codes via the callback-url API will be listed here, where you can revoke their authorizations."
		}

		return "Swipe left to revoke integration authorization. For the revoked integration App to fetch tokens again, a new authorization will have to be performed."
	}

	func configureCell(_ cell: UITableViewCell, withIntegration integration: Integration)
	{
		guard let tokenAccount = integration.tokenAccount, let token = tokenStore?.load(tokenAccount) else
		{
			return
		}

		(cell as? IntegrationTableViewCell)?.setLabels(with: integration, token: token)
	}
}

extension IntegrationsTableViewController: NSFetchedResultsControllerDelegate
{
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
	{
		tableView.beginUpdates()
	}

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
					didChange sectionInfo: NSFetchedResultsSectionInfo,
					atSectionIndex sectionIndex: Int,
					for type: NSFetchedResultsChangeType)
	{
		switch type
		{
		case .insert:
			tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
		case .delete:
			tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
		default:
			return
		}
	}

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
					didChange anObject: Any,
					at indexPath: IndexPath?,
					for type: NSFetchedResultsChangeType,
					newIndexPath: IndexPath?)
	{
		switch type {
		case .insert:
			tableView.insertRows(at: [newIndexPath!], with: .fade)
		case .delete:
			tableView.deleteRows(at: [indexPath!], with: .fade)
		case .update:
			configureCell(tableView.cellForRow(at: indexPath!)!, withIntegration: anObject as! Integration)
		case .move:
			configureCell(tableView.cellForRow(at: indexPath!)!, withIntegration: anObject as! Integration)
			tableView.moveRow(at: indexPath!, to: newIndexPath!)
		}
	}

	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
	{
		tableView.endUpdates()
	}
}

class IntegrationTableViewCell: UITableViewCell
{
	@IBOutlet weak var appNameLabel: UILabel!
	@IBOutlet weak var detailLabel: UILabel!
	@IBOutlet weak var tokenLabel: UILabel!
	@IBOutlet weak var authorizedDateLabel: UILabel!
	@IBOutlet weak var lastUsedDateLabel: UILabel!

	static var dateFormatter: DateFormatter =
	{
		let dateFormatter = DateFormatter()
		dateFormatter.timeStyle = .medium
		dateFormatter.dateStyle = .medium
		return dateFormatter
	}()

	func setLabels(with integration: Integration, token: Token)
	{
		appNameLabel.text = integration.appName
		detailLabel.text = integration.detail
		authorizedDateLabel.text = IntegrationTableViewCell.dateFormatter.string(from: integration.authorized!)
		tokenLabel.text = "\(token.resolvedIssuer) (\(token.resolvedLabel))"

		if let lastUsed = integration.lastUsed
		{
			lastUsedDateLabel.text = IntegrationTableViewCell.dateFormatter.string(from: lastUsed)
		}
		else
		{
			lastUsedDateLabel.text = "Never"
		}
	}
}
