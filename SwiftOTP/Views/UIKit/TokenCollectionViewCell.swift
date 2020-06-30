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
	@IBOutlet private var issuerLabel: UILabel!
	@IBOutlet private var accountLabel: UILabel!
	@IBOutlet private var codeLabel: UILabel!
	@IBOutlet private var buttonsStackView: UIStackView!

	@IBOutlet private var editTokenButton: UIButton!
	@IBOutlet private var showSecretButton: UIButton!
	@IBOutlet private var copySecretButton: UIButton!

	/// Weak reference to the most recently used progress view, so it can be removed on demand if the user hides the
	/// code before its display timeout runs.
	private weak var lastProgressView: UIProgressView? = nil

	private var didEnterBackgroundObserver: NSObjectProtocol? = nil

	/// Callback invoked to request the current codes.
	var codesFetcher: (() -> [Token.Code]?)? = nil

	/// Handler called when the user taps the "edit token" button.
	var editAction: (() -> Void)? = nil

	/// Handler invoked when the user taps the "copy code" button. Should return true on success, false on failure.
	var copyCodeAction: (() -> Bool)? = nil

	/// Hook action invoked when the user taps the "show code" button.
	var showHookAction: (() -> Void)? = nil

	/// Infers whether the code label is currently visible.
	private var codeIsVisible: Bool
	{
		return !(codeLabel.isHidden || codeLabel.alpha == 0.0)
	}

	override func awakeFromNib()
	{
		super.awakeFromNib()

		didEnterBackgroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
																			object: UIApplication.shared,
																			queue: OperationQueue.main)
		{
			[weak self] _ in self?.hideSecret(animated: false)
		}
	}

	deinit
	{
		if let didEnterBackgroundObserver = self.didEnterBackgroundObserver
		{
			NotificationCenter.default.removeObserver(didEnterBackgroundObserver)
		}
	}

	override func removeFromSuperview()
	{
		super.removeFromSuperview()

		destroyTokenReferences()
	}

	override func prepareForReuse()
	{
		super.prepareForReuse()

		destroyTokenReferences()
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

	@IBAction func copySecret(_ sender: Any)
	{
		hideSecret()

		if copyCodeAction?() == true
		{
			animateCopyCodeButtonSuccess()
		}
	}

	/// Sets the token issuer and account labels.
	func setToken(issuer: String, account: String)
	{
		issuerLabel.text = issuer
		issuerLabel.textColor = issuer.isEmpty ? .tertiaryLabel : .label

		accountLabel.text = account
		accountLabel.textColor = account.isEmpty ? .tertiaryLabel : .label

		let tokenHint = "\(account) at \(issuer)"
		editTokenButton.accessibilityHint = tokenHint
		showSecretButton.accessibilityHint = tokenHint
		copySecretButton.accessibilityHint = tokenHint
	}

	private func destroyTokenReferences()
	{
		codesFetcher = nil
		editAction = nil
		copyCodeAction = nil
		showHookAction = nil
		issuerLabel.text = nil
		accountLabel.text = nil
	}

	private func hideSecret(animated: Bool = true)
	{
		if codeIsVisible
		{
			changeCodeVisibility(to: false, animated: animated)
		}
	}

	private func changeCodeVisibility(to showCode: Bool, animated: Bool = true)
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

		// Change accessibility label of show code button
		showSecretButton.accessibilityLabel = showCode ? "Hide Code" : "Show Code"

		// Setup labels alpha transition animations
		self.codeLabel.alpha = showCode ? 0.0 : 1.0
		self.issuerLabel.alpha = showCode ? 1.0 : 0.0
		self.accountLabel.alpha = showCode ? 1.0 : 0.0

		// Run labels alpha transition animations
		UIView.animate(withDuration: animated ? 0.3 : 0.0)
		{
			self.codeLabel.alpha = !showCode ? 0.0 : 1.0
			self.issuerLabel.alpha = !showCode ? 1.0 : 0.0
			self.accountLabel.alpha = !showCode ? 1.0 : 0.0
		}

		// Clear the code label if hiding
		guard showCode else
		{
			codeLabel.text = ""
			if animated
			{
				lastProgressView?.animatedHideAndRemoveFromSuperview()
			}
			else
			{
				lastProgressView?.removeFromSuperview()
			}
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
				guard self.codeIsVisible else
				{
					// If the user hid the code label, then don't do anything.
					return
				}

				self.changeCodeVisibility(to: false)

				// Make show code button active for accessibility
				UIAccessibility.post(notification: .layoutChanged, argument: self.showSecretButton)
			}

			// Show the next code and setup the progress bar
			self.codeLabel.text = nextCode.value

			// Inform accessibilty engine why code changed
			UIAccessibility.post(notification: .announcement, argument: "Code expired. Loading new code.")

			// Make code label active for accessibility
			UIAccessibility.post(notification: .layoutChanged, argument: self.codeLabel)

			// Begin animation of progress view
			self.animateProgress(from: Float(remainingDuration / totalDuration), to: 0.0, duration: remainingDuration)
		}

		// Show the current code and setup the progress bar
		// Note: The following code runs *before* the block of code inside the dispatch call above.
		codeLabel.text = currentCode.value

		// Make code label active for accessibility
		UIAccessibility.post(notification: .layoutChanged, argument: codeLabel)

		// Begin animation of progress view
		animateProgress(from: Float(remainingDuration / totalDuration), to: 0.0, duration: remainingDuration)
	}

	private func animateCopyCodeButtonSuccess()
	{
		guard let copyButton = copySecretButton else
		{
			return
		}

		// Inform accessibilty engine that code was copied
		UIAccessibility.post(notification: .announcement, argument: "Code copied.")

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
		progressView.isAccessibilityElement = false
		progressView.isUserInteractionEnabled = false
		progressView.alpha = 0.0
		if #available(iOS 13.0, *) {
			progressView.trackTintColor = .systemFill
		} else {
			progressView.trackTintColor = .lightGray
		}
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
	/// Sets up a linear animation between `start` and `end progress values, that lasts for `duration`.
	func animateProgress(from start: Float, to end: Float, duration: TimeInterval)
	{
		let start = max(min(0.99999, start), 0.00001)
		let end = max(min(0.99999, end), 0.00001)

		progress = start

		// Ensure the progress layer is sized to the correct proportions for the start value.
		layoutIfNeeded()

		// Invoke the animation code.
		UIView.animate(withDuration: duration, delay: 0.0, options: [.curveLinear, .beginFromCurrentState], animations: {
			self.setProgress(end, animated: true)
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
