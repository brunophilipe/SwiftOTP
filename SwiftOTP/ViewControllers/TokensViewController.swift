//
//  TokensViewController.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 7/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit
import OTPKit
import Intents

#if !targetEnvironment(simulator)
import QRCodeReader
#endif

class TokensViewController: UICollectionViewController
{
	private let tokenStore = TokenStore(accountUUID: Constants.tokenStoreUUID,
										keychainGroupIdentifier: Constants.keychainGroupIdentifier)

	private let reuseIdentifier = "CellToken"

	private enum Segues: String, Segue
	{
		case editToken
	}

	#if !targetEnvironment(simulator)
	// Good practice: create the reader lazily to avoid cpu overload during the
	// initialization and each time we need to scan a QRCode
	lazy var readerVC: QRCodeReaderViewController = {
		let builder = QRCodeReaderViewControllerBuilder {
			$0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
		}
		return QRCodeReaderViewController(builder: builder)
	}()
	#endif

    override func viewDidLoad()
	{
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Do any additional setup after loading the view.
		collectionView.register(UINib(nibName: "TokenCollectionViewCell", bundle: .main),
								forCellWithReuseIdentifier: reuseIdentifier)
    }

	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)

		AppDelegate.shared.mainViewControllerDidAppear()
	}

	@IBAction func showQRReader(_ sender: Any)
	{
		#if targetEnvironment(simulator)

		let alertController = UIAlertController(title: "OTP URL", message: "Insert OTP url:", preferredStyle: .alert)
		alertController.addTextField()
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		alertController.addAction(UIAlertAction(title: "OK", style: .default, handler:
			{
				_ in

				if let text = alertController.textFields?.first?.text,
					let urlComponents = URLComponents(string: text)
				{
					self.importToken(with: urlComponents)
				}
			}))

		present(alertController, animated: true)

		#else

		readerVC.delegate = self

		// Presents the readerVC as modal form sheet
		readerVC.modalPresentationStyle = .formSheet
		present(readerVC, animated: true)
		{
			self.readerVC.startScanning()
		}

		#endif
	}

	private func showAlertBadScan()
	{
		let alertController = UIAlertController(title: "Error",
												message: "This does not seem to be a valid TOTP/HOTP QR Code. Please try again.",
												preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
		present(alertController, animated: true)
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
	{
		super.traitCollectionDidChange(previousTraitCollection)

		navigationController?.navigationBar.prefersLargeTitles = traitCollection.horizontalSizeClass == .compact
	}

	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()

		if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
		{
			let isCompact = traitCollection.horizontalSizeClass == .compact
			let containerWidth = collectionView.effectiveContentSize.width - flowLayout.minimumHorizontalSpacing
			let targetWidth: CGFloat = isCompact ? 145 : 200
			let fittingItems = floor(containerWidth / targetWidth)
			let itemWidth = floor(containerWidth / fittingItems) - (isCompact ? 0 : (fittingItems + 1))

			if itemWidth != flowLayout.itemSize.width
			{
				flowLayout.itemSize.width = itemWidth
			}
		}
	}

	// MARK: - Navigation

	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for storyboardSegue: UIStoryboardSegue, sender: Any?)
	{
		guard let identifier = storyboardSegue.identifier, let segue = Segues(rawValue: identifier) else
		{
			return
		}

		switch segue
		{
		case .editToken:
			if let tokenAccount = sender as? String, let token = tokenStore.load(tokenAccount)
			{
				let deleteAction: (String) -> Void =
					{
						tokenAccount in

						if let token = self.tokenStore.load(tokenAccount)
						{
							self.deleteToken(token)
						}
					}

				let saveAction: ((account: String, issuer: String, label: String)) -> Void =
					{
						tokenInfo in

						if let token = self.tokenStore.load(tokenInfo.account)
						{
							// Setting to nil will reset these values to their original value
							token.issuer = tokenInfo.issuer.count > 0 ? tokenInfo.issuer : nil
							token.label = tokenInfo.label.count > 0 ? tokenInfo.label : nil

							Token.store.save(token)

							self.deleteDonatedIntents(for: token.account)

							if let index = self.tokenStore.index(of: token)
							{
								self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
							}
						}
					}

				let context = EditTokenViewController.TokenEditorContext(tokenAccount: token.account,
																		 tokenIssuer: token.issuer,
																		 tokenLabel: token.label,
																		 deleteAction: deleteAction,
																		 saveAction: saveAction)

				storyboardSegue.destination.broadcast(context)
			}
		}
	}

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int
	{
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
        return tokenStore.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
		if let token = tokenStore.load(indexPath.row), let tokenCell = cell as? TokenCollectionViewCell
		{
			tokenCell.setToken(issuer: token.resolvedIssuer, account: token.resolvedLabel)

			let tokenAccount = token.account
			tokenCell.codesFetcher = { [weak self] in self?.tokenStore.load(tokenAccount)?.codes }
			tokenCell.editAction = { [weak self] in self?.performSegue(Segues.editToken, sender: tokenAccount) }
			tokenCell.showHookAction = { [weak self] in self?.donateIntent(for: tokenAccount) }
			tokenCell.copyCodeAction = { [weak self] in return self?.copyCode(for: tokenAccount) ?? false }
		}
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

private extension TokensViewController
{
	func importToken(with urlComponents: URLComponents)
	{
		guard let _ = tokenStore.add(urlComponents) else
		{
			showAlertBadScan()
			return
		}

		let newIndexPath = IndexPath(item: 0, section: 0)
		collectionView.insertItems(at: [newIndexPath])

		if let cell = collectionView.cellForItem(at: newIndexPath)
		{
			UIAccessibility.post(notification: .layoutChanged, argument: cell)
		}
	}

	func deleteToken(_ token: Token)
	{
		deleteDonatedIntents(for: token.account)

		if let index = tokenStore.index(of: token), tokenStore.erase(token: token)
		{
			collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
		}
	}

	func copyCode(for tokenAccount: String) -> Bool
	{
		guard let token = tokenStore.load(tokenAccount), let bestCode = token.bestCode?.value else
		{
			// There's nothing to show if the codes fetcher failed.
			return false
		}

		let preferences = Preferences.instance

		UIPasteboard.general.setItems([["public.plain-text": bestCode]], options: [
			.expirationDate: Date(timeIntervalSinceNow: preferences.clipboardExpirationLength.timeIntervalValue),
			.localOnly: !preferences.allowClipboardHandoff
		])

		return true
	}
}

extension TokensViewController // Intents
{
	private func donateIntent(for tokenAccount: String)
	{
		guard #available(iOS 12.0, *), let token = tokenStore.load(tokenAccount) else
		{
			return
		}

		let intent = ViewCodeIntent()
		intent.account = token.account
		intent.issuer = token.issuer
		intent.label = token.label

		if let issuer = intent.issuer
		{
			intent.suggestedInvocationPhrase = "OTP \(issuer)"
		}

		let interaction = INInteraction(intent: intent, response: nil)
		interaction.identifier = token.account
		interaction.donate
		{
			error in

			if let error = error
			{
				print("\(error.localizedDescription)")
			}
		}
	}

	private func deleteDonatedIntents(for tokenAcount: String)
	{
		guard #available(iOS 12.0, *) else
		{
			return
		}

		INInteraction.delete(with: [tokenAcount], completion: {
			error in

			if let error = error
			{
				NSLog("Failed deleting interaction: \(error)")
			}
		})
	}
}

extension TokensViewController // Context Bus
{
	override func broadcast(_ context: Any)
	{
		super.broadcast(context)

		if let intentContext = context as? ShowCodeFromIntentContext
		{
			if let index = tokenStore.index(of: intentContext.tokenAccount),
				let tokenCell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? TokenCollectionViewCell
			{
				tokenCell.showSecret(intentContext)
			}
		}
		else if let tokenUrlContext = context as? LoadTokenUrlContext
		{
			importToken(with: tokenUrlContext.urlComponents)
		}
	}

	struct ShowCodeFromIntentContext
	{
		let tokenAccount: String
	}

	struct LoadTokenUrlContext
	{
		let urlComponents: URLComponents
	}
}

#if !targetEnvironment(simulator)
extension TokensViewController: QRCodeReaderViewControllerDelegate
{
	func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult)
	{
		reader.stopScanning()
		reader.dismiss(animated: true)
			{
				[weak self] in

				if let resultUrlComponents = URLComponents(string: result.value)
				{
					self?.importToken(with: resultUrlComponents)
				}
				else
				{
					self?.showAlertBadScan()
				}
			}
	}

	func readerDidCancel(_ reader: QRCodeReaderViewController)
	{
		reader.stopScanning()
		reader.dismiss(animated: true)
	}
}
#endif

private extension UICollectionView
{
	var effectiveContentSize: CGSize
	{
		return frame.inset(by: layoutMargins).size
	}
}

private extension UICollectionViewFlowLayout
{
	var minimumHorizontalSpacing: CGFloat
	{
		return minimumInteritemSpacing + sectionInset.left + sectionInset.right
	}
}
