//
//  TokensPickerViewController.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 14/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit
import OTPKit

class TokensPickerViewController: UITableViewController
{
	private let tokenStore = TokenStore(accountUUID: Constants.tokenStoreUUID,
										keychainGroupIdentifier: Constants.keychainGroupIdentifier)

	private let reuseIdentifier = "CellToken"

	@IBOutlet private var exportButton: UIBarButtonItem!

	private var selectedTokenAccounts: Set<String> = []
	{
		didSet
		{
			exportButton.isEnabled = selectedTokenAccounts.count > 0
		}
	}

    override func viewDidLoad()
	{
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		if navigationController?.isToolbarHidden == true
		{
			navigationController?.setToolbarHidden(false, animated: animated)
		}
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)

		if navigationController?.isToolbarHidden == false
		{
			navigationController?.setToolbarHidden(true, animated: animated)
		}
	}

	@IBAction override func selectAll(_ sender: Any?)
	{
		// Add all token accounts to the selected array
		(0..<tokenStore.count).compactMap({tokenStore.loadAccount(at: $0)}).forEach({selectedTokenAccounts.insert($0)})
		tableView.reloadSections(IndexSet(integer: 0), with: .fade)
	}

	@IBAction func selectNone(_ sender: Any?)
	{
		selectedTokenAccounts.removeAll()
		tableView.reloadSections(IndexSet(integer: 0), with: .fade)
	}

	@IBAction func invertSelection(_ sender: Any?)
	{
		var allTokenAccounts = Set<String>(minimumCapacity: tokenStore.count)

		// Add all token accounts to the temporary array
		(0..<tokenStore.count).compactMap({tokenStore.loadAccount(at: $0)}).forEach({allTokenAccounts.insert($0)})

		// Remove currently selected tokens
		selectedTokenAccounts.forEach({allTokenAccounts.remove($0)})

		// Replace the selected tokens set
		selectedTokenAccounts = allTokenAccounts

		// Update table view
		tableView.reloadSections(IndexSet(integer: 0), with: .fade)
	}

	@IBAction func export(_ sender: Any?)
	{
		exportSelectedTokens()
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int
	{
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
        return tokenStore.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        // Configure the cell...
		if let token = tokenStore.load(indexPath.row)
		{
			cell.textLabel?.text = token.issuer
			cell.detailTextLabel?.text = token.label

			cell.accessoryType = selectedTokenAccounts.contains(token.account) ? .checkmark : .none
		}

        return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		tableView.deselectRow(at: indexPath, animated: true)

		guard let token = tokenStore.load(indexPath.row) else
		{
			return
		}

		if selectedTokenAccounts.contains(token.account)
		{
			selectedTokenAccounts.remove(token.account)
			tableView.cellForRow(at: indexPath)?.accessoryType = .none
		}
		else
		{
			selectedTokenAccounts.insert(token.account)
			tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
		}
	}

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

	private func exportSelectedTokens()
	{
		let selectedTokenAccounts = self.selectedTokenAccounts

		guard selectedTokenAccounts.count > 0 else
		{
			return
		}

		enterSecurityContext(reason: "Exporting tokens requires device owner authentication.")
		{
			result in

			if case .error(let error) = result
			{
				self.handle(authenticationError: error)
				return
			}

			guard let exportData = self.tokenStore.exportData(for: selectedTokenAccounts) else
			{
				self.presentError(message: "Could not generate export file.")
				return
			}

			guard let cachesUrl = FileManager.default.cachesDirectoryUrl else
			{
				self.presentError(message: "Could not find temporary files directory.")
				return
			}

			let formatter = DateFormatter()
			formatter.dateFormat = "yyyy-MM-dd'T'HHmmssZZZZZ"

			let exportFileName = "SwiftOTP-Tokens-\(formatter.string(from: Date())).txt"
			let exportFileUrl = cachesUrl.appendingPathComponent(exportFileName)

			do
			{
				try exportData.write(to: exportFileUrl)
			}
			catch
			{
				self.presentError(message: "Could not write the export file.")
				return
			}

			let destinationPicker = ExportDocumentPickerViewController(urls: [exportFileUrl], in: .moveToService)
			destinationPicker.allowsMultipleSelection = false
			destinationPicker.modalPresentationStyle = .pageSheet
			destinationPicker.delegate = self
			destinationPicker.originalFileUrl = exportFileUrl
			self.present(destinationPicker, animated: true, completion: nil)
		}
	}
}

private class ExportDocumentPickerViewController: UIDocumentPickerViewController
{
	var originalFileUrl: URL? = nil
}

extension TokensPickerViewController: UIDocumentPickerDelegate
{
	func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController)
	{
		if let exportFileUrl = (controller as? ExportDocumentPickerViewController)?.originalFileUrl
		{
			try? FileManager.default.removeItem(at: exportFileUrl)
		}
	}

	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
	{
		if let exportFileUrl = (controller as? ExportDocumentPickerViewController)?.originalFileUrl
		{
			try? FileManager.default.removeItem(at: exportFileUrl)
		}
	}
}
