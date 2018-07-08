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

	@IBOutlet private var editTokenButton: UIButton!
	@IBOutlet private var showSecretButton: UIButton!
	@IBOutlet private var copySecretButton: UIButton!

	@IBAction func editToken(_ sender: Any)
	{
	}

	@IBAction func showSecret(_ sender: Any)
	{
	}

	@IBAction func copySecret(_ sender: Any)
	{
	}

	func setToken(_ token: Token)
	{
		titleLabel.text = token.issuer
		accountLabel.text = token.label
	}
}
