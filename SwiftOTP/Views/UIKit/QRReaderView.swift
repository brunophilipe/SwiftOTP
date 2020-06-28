//
//  QRReaderView.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 28.06.20.
//  Copyright © 2020 Bruno Philipe. All rights reserved.
//

import UIKit
import QRCodeReader

class QRReaderView: UIView, QRCodeReaderDisplayable {

	@IBOutlet unowned var cancelButton: UIButton?
	@IBOutlet unowned var switchCameraButton: UIButton?
	@IBOutlet unowned var toggleTorchButton: UIButton?

	@IBOutlet unowned var cancelButtonVisualEffectView: UIVisualEffectView!
	@IBOutlet unowned var actionButtonsButtonVisualEffectView: UIVisualEffectView!

	var cameraView: UIView {
		return self
	}

	let overlayView: QRCodeReaderViewOverlay? = ReaderOverlayView()

	func setupComponents(with builder: QRCodeReaderViewControllerBuilder) {
		layer.insertSublayer(builder.reader.previewLayer, at: 0)

		cancelButtonVisualEffectView.layer.cornerRadius = 10
		cancelButtonVisualEffectView.layer.cornerCurve = .continuous
		cancelButtonVisualEffectView.clipsToBounds = true

		actionButtonsButtonVisualEffectView.layer.cornerRadius = 10
		cancelButtonVisualEffectView.layer.cornerCurve = .continuous
		actionButtonsButtonVisualEffectView.clipsToBounds = true
	}

	func setNeedsUpdateOrientation() {

	}

	static func make() -> QRReaderView {
		UINib(nibName: "QRReaderView", bundle: .main).instantiate(withOwner: nil, options: nil).first as! QRReaderView
	}
}
