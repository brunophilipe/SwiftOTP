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
	private var clientSecret: String? = nil

	@IBOutlet var codeLabel: UILabel!

	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}

	@IBAction func fetchCode(_ sender: Any?)
	{
		// This demo app uses the CallbackURLKit library to manage the boilerplate code of callback-url handling.
		let callbackClient = CallbackClient(urlScheme: "swiftotp-callback")

		// SwiftOTP requires an app to identify itself with a UUID, which should be the same for every OTP request.
		// If your app supports using multiple OTP codes (for example, if it supports multiple accounts), then it
		// should provide different UUIDs for each OTP code (for each account).
		let demoUUID = UUID(uuidString: "ABB86AD9-0437-4523-A86E-BBEC3F557BF7")!

		var parameters: [String: String] = [
			"client_id": demoUUID.uuidString,
			"client_app": "SwiftOTP Demo App",
			"client_detail": "demoaccount@example.com"
		]

		if let clientSecret = self.clientSecret
		{
			parameters["client_secret"] = clientSecret
		}

		do
		{
			try callbackClient.perform(action: "fetch-code", parameters: parameters, onSuccess: { [weak self] (result) in
				if let code = result?["code"]
				{
					self?.codeLabel.text = code
				}

				if let clientSecret = result?["client_secret"]
				{
					self?.clientSecret = clientSecret
				}
			}, onFailure: { [weak self] (result) in
				self?.codeLabel.text = "Failure!"
			}, onCancel: { [weak self] in
				self?.codeLabel.text = "Canceled!"
			})
		}
		catch
		{
			#if DEBUG
			NSLog("Failed fetching code: \(error)")
			#endif
		}
	}
}

