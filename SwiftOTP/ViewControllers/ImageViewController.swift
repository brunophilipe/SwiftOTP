//
//  ImageViewController.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 12/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController
{
	@IBOutlet var imageView: UIImageView!

	override func viewDidLoad()
	{
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
    }

	@IBAction func done(_ sender: Any?)
	{
		dismiss(animated: true)
	}

	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()

		// Perform these checks to avoid a "did layout subviews" infinite loop
		if let imageView = self.imageView
		{
			let desiredContentMode: UIView.ContentMode = imageView.imageFits ? .center : .scaleAspectFit

			if imageView.contentMode != desiredContentMode
			{
				imageView.contentMode = desiredContentMode
			}
		}
	}

	override func broadcast(_ context: Any)
	{
		super.broadcast(context)

		if let imageContext = context as? ImageContext
		{
			loadViewIfNeeded()

			imageView.image = imageContext.image
			navigationItem.title = imageContext.title
		}
	}

	struct ImageContext
	{
		let image: UIImage
		let title: String?
	}
}

private extension UIImageView
{
	var imageFits: Bool
	{
		guard let image = self.image else
		{
			return true
		}

		return frame.width > image.size.width && frame.height > image.size.height
	}
}
