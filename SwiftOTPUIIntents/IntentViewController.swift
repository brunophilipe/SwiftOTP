//
//  IntentViewController.swift
//  SwiftOTPUIIntents
//
//  Created by Bruno Philipe on 28.06.20.
//  Copyright © 2020 Bruno Philipe. All rights reserved.
//

import IntentsUI
import OTPKit

class IntentViewController: UIViewController, INUIHostedViewControlling {

	private let tokenStore = TokenStore(accountUUID: Constants.tokenStoreUUID,
										keychainGroupIdentifier: Constants.keychainGroupIdentifier)

	@IBOutlet unowned var codeLabel: UILabel!
	@IBOutlet unowned var issuerLabel: UILabel!
	@IBOutlet unowned var labelLabel: UILabel!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}

	// MARK: - INUIHostedViewControlling

	// Prepare your view controller for the interaction to handle.
	func configureView(for parameters: Set<INParameter>,
					   of interaction: INInteraction,
					   interactiveBehavior: INUIInteractiveBehavior,
					   context: INUIHostedViewContext,
					   completion: @escaping (Bool, Set<INParameter>, CGSize) -> Void) {

		guard let response = interaction.intentResponse as? ViewCodeIntentResponse,
			  let token = response.account.flatMap({ tokenStore.load($0) }) else {
			completion(false, parameters, .zero)
			return
		}

		codeLabel.text = response.otpCode?.dividedIntoClusters()
		issuerLabel.text = token.issuer
		labelLabel.text = token.label

		completion(true, parameters, self.desiredSize)
	}

	var desiredSize: CGSize {
		return view.systemLayoutSizeFitting(extensionContext!.hostedViewMaximumAllowedSize)
	}

}
