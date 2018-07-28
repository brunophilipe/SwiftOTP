//
//  TokensExportViewController.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 26/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

class TokensExportViewController: TokensPickerViewController
{
	@IBOutlet private var exportButton: UIBarButtonItem!

	override func viewDidLoad()
	{
		super.viewDidLoad()

		tableView.allowsMultipleSelection = true
	}

	@IBAction func export(_ sender: Any?)
	{
		exportSelectedTokens()
	}

	override var selectedTokenAccounts: Set<String>
	{
		didSet
		{
			exportButton.isEnabled = selectedTokenAccounts.count > 0
		}
	}

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

extension TokensExportViewController: UIDocumentPickerDelegate
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
