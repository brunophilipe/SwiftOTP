//
//  IntegrationTokenViewController.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 28/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

class IntegrationTokenViewController: TokensPickerViewController
{
	@IBOutlet private var doneButton: UIBarButtonItem!

	var successHandler: ((String) -> Void)? = nil
	var cancelHandler: (() -> Void)? = nil

	override var selectedTokenAccounts: Set<String>
	{
		didSet
		{
			doneButton.isEnabled = selectedTokenAccounts.count > 0
		}
	}

	@IBAction func done(_ sender: Any?)
	{
		guard let successHandler = self.successHandler, let tokenAccount = selectedTokenAccounts.first else
		{
			return
		}

		successHandler(tokenAccount)
	}

	@IBAction func cancel(_ sender: Any?)
	{
		cancelHandler?()
	}
}
