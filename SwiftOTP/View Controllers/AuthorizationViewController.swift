//
//  AuthorizationViewController.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 28/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

class AuthorizationViewController: UITableViewController
{
	@IBOutlet var appNameLabels: [UILabel]!

	private var authorizationContext: AuthorizeIntegrationContext? = nil
	{
		didSet
		{
			if let appName = authorizationContext?.authorizationRequest.clientApp
			{
				loadViewIfNeeded()
				appNameLabels.forEach({ $0.text = $0.text?.replacingOccurrences(of: "<app name>", with: appName) })
			}
		}
	}

	@IBAction func cancel(_ sender: Any?)
	{
		cancelAuthorization()
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		guard let pickerController = segue.destination as? IntegrationTokenViewController else
		{
			return
		}

		pickerController.cancelHandler = { [weak self] in self?.cancelAuthorization() }
		pickerController.successHandler = { [weak self] in self?.completeAuthorization(tokenAccount: $0) }
	}

	private func cancelAuthorization()
	{
		dismiss(animated: true)
		authorizationContext?.failureHandler()
	}

	private func completeAuthorization(tokenAccount: String)
	{
		dismiss(animated: true)
		authorizationContext?.successHandler(tokenAccount)
	}

	struct AuthorizeIntegrationContext
	{
		/// An authorization request object.
		let authorizationRequest: OTPCallbackRouter.AuthorizationRequest

		let failureHandler: () -> Void

		let successHandler: (String) -> Void
	}

	override func broadcast(_ context: Any)
	{
		super.broadcast(context)

		if let authorizationContext = context as? AuthorizeIntegrationContext
		{
			self.authorizationContext = authorizationContext
		}
	}
}
