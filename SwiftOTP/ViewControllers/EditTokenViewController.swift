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

    override func viewDidLoad()
	{
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		if indexPath.section == 2, indexPath.row == 0
		{
			deleteToken(tableView.cellForRow(at: indexPath) as Any)
		}
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
		var tokenAccount: String
		var tokenIssuer: String
		var tokenLabel: String
		var deleteAction: (String) -> Void
		var saveAction: ((account: String, issuer: String, label: String)) -> Void
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
