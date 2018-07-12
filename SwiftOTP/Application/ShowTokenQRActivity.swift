//
//  ShowTokenQRActivity.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 12/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

class ShowTokenQRActivity: UIActivity
{
	private var url: URL? = nil

	override class var activityCategory: UIActivity.Category
	{
		return .action
	}

	override var activityTitle: String?
	{
		return "Show Token QR Code"
	}

	override var activityType: UIActivity.ActivityType?
	{
		return .init(rawValue: "Show")
	}

	override var activityImage: UIImage?
	{
		return #imageLiteral(resourceName: "QR_Large.pdf")
	}

	override func canPerform(withActivityItems activityItems: [Any]) -> Bool
	{
		guard activityItems.count == 1, let url = activityItems.first as? URL else
		{
			return false
		}

		self.url = url

		return true
	}

	override var activityViewController: UIViewController?
	{
		let imageViewerStoryboard = UIStoryboard(name: "ImageViewer", bundle: Bundle.main)

		let qrSize = CGSize(width: 300, height: 300)
		let qrScale = UIScreen.main.scale

		guard
			let imageViewController = imageViewerStoryboard.instantiateInitialViewController(),
			let qrString = url?.absoluteString,
			let qrImage = UIImage(qrString: qrString, size: qrSize, scale: qrScale, errorCorrectionLevel: .low)
			else
		{
			return nil
		}

		imageViewController.modalPresentationStyle = .formSheet
		imageViewController.preferredContentSize = CGSize(width: qrSize.width + 32, height: qrSize.height + 16)
		imageViewController.broadcast(ImageViewController.ImageContext(image: qrImage, title: "Token QR Code"))

		return imageViewController
	}
}
