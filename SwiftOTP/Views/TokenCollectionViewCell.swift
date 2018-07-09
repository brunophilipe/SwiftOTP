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
	@IBOutlet private var buttonsStackView: UIStackView!

	@IBOutlet private var editTokenButton: UIButton!
	@IBOutlet private var showSecretButton: UIButton!
	@IBOutlet private var copySecretButton: UIButton!

	private weak var lastProgressView: UIProgressView? = nil

	var codesFetcher: (() -> [Token.Code]?)? = nil

	/// Handler called when the user taps the "edit token" button.
	var editAction: (() -> Void)? = nil

	/// Handler invoked when the user taps the "copy code" button. Should return true on success, false on failure.
	var copyCodeAction: (() -> Bool)? = nil

	var showHookAction: (() -> Void)? = nil

	private var codeIsVisible: Bool
	{
		return !(codeLabel.isHidden || codeLabel.alpha == 0.0)
	}

	@IBAction func editToken(_ sender: Any)
	{
		editAction?()
	}

	@IBAction func showSecret(_ sender: Any)
	{
		if !codeIsVisible
		{
			// Only invoke the hook when the code is going to be shown to the user.
			showHookAction?()
		}

		// Effectively toggles the visibility
		changeCodeVisibility(to: !codeIsVisible)
	}

	func hideSecret()
	{
		if codeIsVisible
		{
			changeCodeVisibility(to: false)
		}
	}

	@IBAction func copySecret(_ sender: Any)
	{
		hideSecret()

		if copyCodeAction?() == true
		{
			animateCopyCodeButtonSuccess()
		}
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

	private func changeCodeVisibility(to showCode: Bool)
	{
		guard let codes = codesFetcher?(), codes.count >= 2 else
		{
			// There's nothing to show if the codes fetcher failed.
			return
		}

		// On the nib, the code label is set as hidden, but after the first time the animation runs, it isn't, so
		// we use the alpha being zero, and we stop using the hidden bool.
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

		// Clear the code label if hiding
		guard showCode else
		{
			codeLabel.text = ""
			lastProgressView?.animatedHideAndRemoveFromSuperview()
			return
		}

		// Show the current code
		let currentCode = codes.first!
		let nextCode = codes.last!
		let totalDuration = currentCode.to.timeIntervalSince(currentCode.from)
		let remainingDuration = currentCode.to.timeIntervalSince(Date())

		// Very important that this async call runs on time
		DispatchQueue.main.asyncAfter(wallDeadline: .now() + remainingDuration, qos: .userInteractive, flags: .enforceQoS)
		{
			guard self.codeIsVisible else
			{
				// If the user hid the code label, then don't show it again!
				return
			}

			let totalDuration = nextCode.to.timeIntervalSince(nextCode.from)
			let remainingDuration = nextCode.to.timeIntervalSince(Date())

			// This one is less important that it runs on time
			DispatchQueue.main.asyncAfter(wallDeadline: .now() + remainingDuration)
			{
				self.changeCodeVisibility(to: false)
			}

			// Show the next code and setup the progress bar
			self.codeLabel.text = nextCode.value
			self.animateProgress(from: Float(remainingDuration / totalDuration), to: 0.0, duration: remainingDuration)
		}

		// Show the current code and setup the progress bar
		// Note: The following code runs *before* the block of code inside the dispatch call above.
		codeLabel.text = currentCode.value
		animateProgress(from: Float(remainingDuration / totalDuration), to: 0.0, duration: remainingDuration)
	}

	private func animateCopyCodeButtonSuccess()
	{
		guard let copyButton = copySecretButton else
		{
			return
		}

		copyButton.setNormalAppearance(image: #imageLiteral(resourceName: "button_copy_success.pdf"), tint: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1), duration: 0.3)

		DispatchQueue.main.asyncAfter(wallDeadline: .now() + 2.3)
		{
			copyButton.setNormalAppearance(image: #imageLiteral(resourceName: "button_copy.pdf"), tint: self.tintColor, duration: 0.3)
		}
	}

	private func animateProgress(from start: Float, to end: Float, duration: TimeInterval)
	{
		self.lastProgressView?.animatedHideAndRemoveFromSuperview()

		let progressView = UIProgressView(progressViewStyle: .bar)
		progressView.translatesAutoresizingMaskIntoConstraints = false
		progressView.alpha = 0.0
		addSubview(progressView)

		NSLayoutConstraint.activate([
			leadingAnchor.constraint(equalTo: progressView.leadingAnchor),
			progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
			buttonsStackView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 1.0)
		])

		progressView.animatedShow()
		progressView.animateProgress(from: start, to: end, duration: duration)

		self.lastProgressView = progressView
	}
}

private extension UIProgressView
{
	func animateProgress(from start: Float, to end: Float, duration: TimeInterval)
	{
		progress = start
		layoutIfNeeded()
		setProgress(end, animationDuration: duration)
	}

	func setProgress(_ progress: Float, animationDuration: TimeInterval)
	{
		UIView.animate(withDuration: animationDuration, delay: 0.0, options: [.curveLinear, .beginFromCurrentState], animations: {
			self.setProgress(progress, animated: true)
		})
	}
}

private extension UIButton
{
	func setNormalAppearance(image: UIImage, tint: UIColor, duration: TimeInterval)
	{
		UIView.transition(with: self, duration: duration, options: .transitionCrossDissolve, animations:
			{
				self.tintColor = tint
				self.setImage(image, for: .normal)
			})
	}
}
