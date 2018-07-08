//
//  TokensViewController.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 7/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit
import OTPKit
import QRCodeReader

class TokensViewController: UICollectionViewController
{
	private let tokenStore = TokenStore(accountUUID: AppDelegate.storeUUID)
	private let reuseIdentifier = "CellToken"

	// Good practice: create the reader lazily to avoid cpu overload during the
	// initialization and each time we need to scan a QRCode
	lazy var readerVC: QRCodeReaderViewController = {
		let builder = QRCodeReaderViewControllerBuilder {
			$0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
		}
		return QRCodeReaderViewController(builder: builder)
	}()

    override func viewDidLoad()
	{
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Do any additional setup after loading the view.
		collectionView.register(UINib(nibName: "TokenCollectionViewCell", bundle: .main),
								forCellWithReuseIdentifier: reuseIdentifier)
    }

	@IBAction func showQRReader(_ sender: Any)
	{
		readerVC.delegate = self

		// Presents the readerVC as modal form sheet
		readerVC.modalPresentationStyle = .formSheet
		present(readerVC, animated: true)
		{
			self.readerVC.startScanning()
		}
	}

	private func importToken(with urlComponents: URLComponents)
	{
		guard let _ = tokenStore.add(urlComponents) else
		{
			showAlertBadScan()
			return
		}

		// TODO: Insert new token (need to find out how tokens are indexed first)
		collectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
	}

	private func showAlertBadScan()
	{
		let alertController = UIAlertController(title: "Error",
												message: "This does not seem to be a valid TOTP/HOTP QR Code. Please try again.",
												preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
		present(alertController, animated: true)
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

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
			tokenCell.setToken(issuer: token.issuer, account: token.label)
			tokenCell.codesFetcher = { token.codes }
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

private extension UICollectionView
{
	var effectiveContentSize: CGSize
	{
		return bounds.inset(by: layoutMargins).size
	}
}

private extension UICollectionViewFlowLayout
{
	var minimumHorizontalSpacing: CGFloat
	{
		return minimumInteritemSpacing + sectionInset.left + sectionInset.right
	}
}
