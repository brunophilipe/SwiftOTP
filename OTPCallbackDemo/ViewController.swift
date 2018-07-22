//
//  ViewController.swift
//  OTPCallbackDemo
//
//  Created by Bruno Philipe on 7/22/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit
import CallbackURLKit

class ViewController: UIViewController
{
	@IBOutlet var codeLabel: UILabel!

	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}

	@IBAction func fetchCode(_ sender: Any?)
	{
		let callbackClient = CallbackClient(urlScheme: "swiftotp-callback")

		do
		{
			try callbackClient.perform(action: "fetch-code", onSuccess: { [weak self] (result) in
				if let code = result?["code"]
				{
					self?.codeLabel.text = code
				}
			}, onFailure: { [weak self] (result) in
				self?.codeLabel.text = "Failure!"
			}, onCancel: { [weak self] in
				self?.codeLabel.text = "Canceled!"
			})
		}
		catch
		{
			NSLog("Failed fetching code: \(error)")
		}
	}
}

