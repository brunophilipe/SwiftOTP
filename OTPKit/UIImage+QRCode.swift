//
//  UIImage+QRCode.swift
//  OTPKit
//
//  Created by Bruno Philipe on 12/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import Foundation

public extension UIImage
{
	/// QR Code correction levels as defined by the ISO/IEC 18004:2015 standard.
	///
	/// Note: Incrasing the error correction level of a QR Code image also increases the amount of data it encodes,
	/// thus producing a larger (denser) image.
	///
	/// - low: 7% of codewords can be restored.
	/// - medium: 15% of codewords can be restored.
	/// - quartile: 25% of codewords can be restored.
	/// - high: 30% of codewords can be restored.
	enum QRCodeCorrectionLevel: String
	{
		case low = "L"
		case medium = "M"
		case quartile = "Q"
		case high = "H"
	}

	/// Create an UIImage by rendering a QR Code that contains the data of the provided string.
	///
	/// - Parameters:
	///   - qrString: The data to embed in the QR Code.
	///   - size: The final size of the QR Code image.
	///   - scale: The scale of the QR Code image. Ideally this matches the target screen's scale.
	///   - errorCorrectionLevel: The error collection level to use when generating the QR Code image.
	convenience init?(qrString: String,
					  size: CGSize = CGSize(width: 128, height: 128),
					  scale: CGFloat = 1.0,
					  errorCorrectionLevel: QRCodeCorrectionLevel = .medium)
	{
		let filterParameters: [String : Any] = [
			"inputMessage": qrString.data(using: .utf8)!,
			"inputCorrectionLevel": errorCorrectionLevel.rawValue
		]

		// Create filter and generate qr code at default size
		guard let ciImage = CIFilter(name: "CIQRCodeGenerator", parameters: filterParameters)?.outputImage else
		{
			return nil
		}

		// Convert the CIImage object to a CGImage object
		guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else
		{
			return nil
		}

		// Begin graphics context so that we can resize the QR code
		UIGraphicsBeginImageContextWithOptions(size, false, scale)

		// Get the graphics context
		guard let context = UIGraphicsGetCurrentContext() else
		{
			return nil
		}

		// Disable interpolation so we get a crisp image (best for QR code upscaling)
		context.interpolationQuality = .none

		// Draw the CGImage in the graphics context
		context.draw(cgImage, in: context.boundingBoxOfClipPath)

		// Get the upscaled image from the graphics context
		guard let upscaledCgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else
		{
			return nil
		}

		// End the graphics context
		UIGraphicsEndImageContext()

		// Initialize self with the final updscaled image by remapping it to the desired scale, and by flipping it
		// vertically to match the iOS graphics orientation.
		self.init(cgImage: upscaledCgImage, scale: scale, orientation: .downMirrored)
	}
}
