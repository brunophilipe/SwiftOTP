//
//  UIViewController+Alerts.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 12/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

extension UIViewController
{
	/// Presents an error alert from the receiver view controller. This method does not provide any callback rountines.
	///
	/// - Parameters:
	///   - title: The title of the error alert. Defaults to "Error".
	///   - message: The message of the error message.
	///   - dismissButtonTitle: The title of the dismiss button. Defaults to "OK".
	func presentAlert(title: String = "Error", message: String, dismissButtonTitle: String = "OK")
	{
		let errorAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		errorAlert.addAction(UIAlertAction(title: dismissButtonTitle, style: .cancel))
		present(errorAlert, animated: true)
	}

	func presentDialog(title: String, message: String,
					   continueActionTitle: String,
					   continueActionIsDestructive: Bool = false,
					   reventActionTitle: String? = nil,
					   dismissActionTitle: String,
					   resultHandler: @escaping (DialogResult) -> Void) {

		let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)

		dialog.addAction(UIAlertAction(title: continueActionTitle,
									   style: continueActionIsDestructive ? .destructive : .default,
									   handler: { _ in resultHandler(.continue) }))

		if let title = reventActionTitle {
			dialog.addAction(.init(title: title, style: .default, handler: { _ in resultHandler(.revert) }))
		}

		dialog.addAction(UIAlertAction(title: dismissActionTitle,
									   style: .cancel,
									   handler: { _ in resultHandler(.dismiss) }))

		present(dialog, animated: true)
	}

	enum DialogResult {
		case `continue`, revert, dismiss
	}
}
