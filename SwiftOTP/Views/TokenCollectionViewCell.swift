//
//  TokenCollectionViewCell.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 7/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit
import OTPKit

class TokenCollectionViewCell: UICollectionViewCell
{
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var accountLabel: UILabel!
	@IBOutlet private var codeLabel: UILabel!

	@IBOutlet private var editTokenButton: UIButton!
	@IBOutlet private var showSecretButton: UIButton!
	@IBOutlet private var copySecretButton: UIButton!

	var codesFetcher: (() -> [Token.Code]?)? = nil

	var editAction: (() -> Void)? = nil

	@IBAction func editToken(_ sender: Any)
	{
		editAction?()
	}

	@IBAction func showSecret(_ sender: Any)
	{
		guard let codes = codesFetcher?(), codes.count >= 2 else
		{
			// There's nothing to show if the codes fetcher failed.
			return
		}

		// On the nib, the code label is set as hidden, but after the first time the animation runs, it isn't, so
		// we use the alpha being zero, and we stop using the hidden bool.
		let showCode = codeLabel.alpha < 1.0 || codeLabel.isHidden
		self.codeLabel.isHidden = false

		// Update show code button icon
		self.showSecretButton.setImage(showCode ? #imageLiteral(resourceName: "button_eye_crossed.pdf"): #imageLiteral(resourceName: "button_eye.pdf"), for: .normal)

		// Setup labels alpha transition animations
		self.codeLabel.alpha = showCode ? 0.0 : 1.0
		self.titleLabel.alpha = showCode ? 1.0 : 0.0
		self.accountLabel.alpha = showCode ? 1.0 : 0.0

		// Run labels alpha transition animations
		UIView.animate(withDuration: 0.3)
		{
			self.codeLabel.alpha = !showCode ? 0.0 : 1.0
			self.titleLabel.alpha = !showCode ? 1.0 : 0.0
			self.accountLabel.alpha = !showCode ? 1.0 : 0.0
		}

		// Show the current code
		let currentCode = codes.first!
		codeLabel.text = currentCode.value
	}

	@IBAction func copySecret(_ sender: Any)
	{
	}

	func setToken(issuer: String?, account: String?)
	{
		if let issuer = issuer, issuer.count > 0
		{
			titleLabel.text = issuer
			titleLabel.textColor = .darkText
		}
		else
		{
			titleLabel.text = "No Issuer"
			titleLabel.textColor = .gray
		}

		if let account = account, account.count > 0
		{
			accountLabel.text = account
			accountLabel.textColor = .darkText
		}
		else
		{
			accountLabel.text = "No Account"
			accountLabel.textColor = .gray
		}
	}
}
