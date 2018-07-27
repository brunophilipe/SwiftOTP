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
	internal var tokenStore: TokenStore
	{
		return AppDelegate.shared.tokenStore
	}

	internal let reuseIdentifier = "CellToken"

	internal var selectedTokenAccounts: Set<String> = []
	{
		didSet
		{
			if selectedTokenAccounts.count > 1, !tableView.allowsMultipleSelection
			{
				// Trim selection to first element
				selectedTokenAccounts = [selectedTokenAccounts.first!]
			}
		}
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

		// If this is a single-selection picker, replace the selection instead of adding to it.
		guard tableView.allowsMultipleSelection else
		{
			// There should be only one selection, but we make sure to un-check all selections if there are many.
			selectedTokenAccounts.forEach
				{
					if let index = tokenStore.index(of: $0)
					{
						tableView.cellForRow(at: IndexPath(row: index, section: 0))?.accessoryType = .none
					}
				}

			tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
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
}
