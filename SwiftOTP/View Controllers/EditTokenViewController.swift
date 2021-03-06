//
//  EditTokenViewController.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 8/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit
import OTPKit

class EditTokenViewController: UITableViewController
{
	@IBOutlet var issuerTextField: UITextField!
	@IBOutlet var labelTextField: UITextField!

	private var context: TokenEditorContext? = nil
	{
		didSet
		{
			loadViewIfNeeded()
			issuerTextField.text = context?.tokenIssuer
			labelTextField.text = context?.tokenLabel
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		if indexPath.section == 2, indexPath.row == 0
		{
			deleteToken(tableView.cellForRow(at: indexPath) as Any)
		}

		tableView.deselectRow(at: indexPath, animated: true)
	}

	@IBAction func saveToken(_ sender: Any)
	{
		guard let context = self.context else
		{
			dismiss(animated: true)
			return
		}

		let issuer = issuerTextField.text ?? context.tokenIssuer
		let label = labelTextField.text ?? context.tokenLabel

		context.saveAction((context.tokenAccount, issuer, label))
		dismiss(animated: true)
	}

	@IBAction func cancelEditor(_ sender: Any)
	{
		dismiss(animated: true)
	}

	@IBAction func deleteToken(_ sender: Any)
	{
		guard let context = self.context else
		{
			return
		}

		let alert = UIAlertController(title: "Attention", message: "Do you really want to delete the token for \(context.tokenIssuer)? This action can not be undone!", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in self.handleDelete() }))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		present(alert, animated: true)
	}

	@IBAction func exportToken(_ sender: Any)
	{
		enterSecurityContext(reason: "Exporting tokens requires authentication.")
		{
			result in

			if case .error(let error) = result
			{
				self.handle(authenticationError: error)
				return
			}

			guard let context = self.context, let url = context.getTokenUrlAction(context.tokenAccount) else
			{
				self.presentAlert(message: "Could not load token secret.")
				return
			}

			let activitySheet = UIActivityViewController(activityItems: [url],
														 applicationActivities: [ShowTokenQRActivity()])

			self.present(activitySheet, animated: true)

			activitySheet.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
		}
	}

	private func handleDelete()
	{
		guard let context = self.context else
		{
			return
		}

		dismiss(animated: true)
		{
			context.deleteAction(context.tokenAccount)
		}
	}

	struct TokenEditorContext
	{
		let tokenAccount: String
		let tokenIssuer: String
		let tokenLabel: String
		let deleteAction: (String) -> Void
		let saveAction: ((account: String, issuer: String, label: String)) -> Void
		let getTokenUrlAction: (String) -> URL?
	}
}

extension EditTokenViewController: UITextFieldDelegate
{
	func textFieldShouldReturn(_ textField: UITextField) -> Bool
	{
		if textField === issuerTextField
		{
			labelTextField.becomeFirstResponder()
		}
		else
		{
			textField.resignFirstResponder()
		}

		return true
	}
}

extension EditTokenViewController
{
	override func broadcast(_ context: Any)
	{
		super.broadcast(context)

		if let tokenContext = context as? TokenEditorContext
		{
			self.context = tokenContext
		}
	}
}
