//
//  PreferencesViewController.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 14/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit
import OTPKit

class PreferencesViewController: UITableViewController
{
	public static let didImportTokensNotificationName = Notification.Name("didImportTokensNotification")
	public static let didDeleteAllTokensNotificationName = Notification.Name("didDeleteAllTokensNotification")

	@IBOutlet var appVersionLabel: UILabel!

	private var tokenStore: TokenStore
	{
		return AppDelegate.shared.tokenStore
	}

	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		if let bundleHumanVersion = Bundle.main.bundleHumanVersion, let bundleVersion = Bundle.main.bundleVersion
		{
			appVersionLabel.text = "\(bundleHumanVersion) (\(bundleVersion))"
		}
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		if navigationController?.isToolbarHidden == false
		{
			navigationController?.setToolbarHidden(true, animated: animated)
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		switch indexPath.tableRowTupleValue
		{
		case (0, 2):
			deleteAll(tableView)
			tableView.deselectRow(at: indexPath, animated: true)

		case (1, 0):
			showFileImportPicker(sender: tableView.cellForRow(at: indexPath))

		case (2, 1):
			let githubURL = URL(string: "https://github.com/brunophilipe/SwiftOTP")!
			UIApplication.shared.open(githubURL, options: [:], completionHandler: nil)
			tableView.deselectRow(at: indexPath, animated: true)

		default:
			break
		}
	}

	private func showFileImportPicker(sender: Any?)
	{
		let filePicker = UIDocumentPickerViewController(documentTypes: AppDelegate.tokenImportUTIs, in: .open)
		filePicker.delegate = self

		present(filePicker, animated: true)
	}

	@IBAction func done(_ sender: Any?)
	{
		dismiss(animated: true)
	}

	@IBAction func deleteAll(_ sender: Any?)
	{
		tokenStore.eraseAll()

		NotificationCenter.default.post(name: PreferencesViewController.didDeleteAllTokensNotificationName, object: self)
	}
}

extension PreferencesViewController: UIDocumentPickerDelegate
{
	public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
	{
		guard let fileUrl = urls.first else
		{
			return
		}

		do
		{
			_ = fileUrl.startAccessingSecurityScopedResource()
			try tokenStore.importData(try Data(contentsOf: fileUrl))
			fileUrl.stopAccessingSecurityScopedResource()
		}
		catch
		{
			if let importError = error as? TokenStore.ImportErrors
			{
				switch importError
				{
				case .unknownFileFormat:
					presentAlert(message: "Could not import tokens from file: File format was unreadable.")

				case .malformedToken(let line):
					presentAlert(message: "Could not import tokens from file: Malformed token URL on line \(line).")

				case .keychainWriteError(let line):
					presentAlert(message: "Could not import tokens from file: Bad token configurations for token on line \(line).")
				}
			}
			else
			{
				presentAlert(message: "Could not import tokens from file. Unknown error: \(error.localizedDescription)")
			}
		}

		presentAlert(title: "Success", message: "Imported tokens file successfully!", dismissButtonTitle: "Dismiss")

		NotificationCenter.default.post(name: PreferencesViewController.didImportTokensNotificationName, object: self)
	}
}
