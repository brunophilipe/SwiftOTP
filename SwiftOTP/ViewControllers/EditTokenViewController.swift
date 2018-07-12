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
		guard let context = self.context, let url = context.getTokenUrlAction(context.tokenAccount) else
		{
			return
		}

		let activitySheet = UIActivityViewController(activityItems: [url], applicationActivities: [ShowTokenQRActivity()])
		present(activitySheet, animated: true)
		activitySheet.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
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

private class ShowTokenQRActivity: UIActivity
{
	private var url: URL? = nil

	override class var activityCategory: UIActivity.Category
	{
		return .action
	}

	override var activityTitle: String?
	{
		return "Show Token QR Code"
	}

	override var activityType: UIActivity.ActivityType?
	{
		return .init(rawValue: "Show")
	}

	override var activityImage: UIImage?
	{
		return #imageLiteral(resourceName: "QR_Large.pdf")
	}

	override func canPerform(withActivityItems activityItems: [Any]) -> Bool
	{
		guard activityItems.count == 1, let url = activityItems.first as? URL else
		{
			return false
		}

		self.url = url

		return true
	}

	override var activityViewController: UIViewController?
	{
		let imageViewerStoryboard = UIStoryboard(name: "ImageViewer", bundle: Bundle.main)

		let qrSize = CGSize(width: 300, height: 300)
		let qrScale = UIScreen.main.scale

		guard
			let imageViewController = imageViewerStoryboard.instantiateInitialViewController(),
			let qrString = url?.absoluteString,
			let qrImage = UIImage(qrString: qrString, size: qrSize, scale: qrScale, errorCorrectionLevel: .low)
		else
		{
			return nil
		}

		imageViewController.modalPresentationStyle = .formSheet
		imageViewController.preferredContentSize = CGSize(width: qrSize.width + 32, height: qrSize.height + 16)
		imageViewController.broadcast(ImageViewController.ImageContext(image: qrImage, title: "Token QR Code"))

		return imageViewController
	}
}
