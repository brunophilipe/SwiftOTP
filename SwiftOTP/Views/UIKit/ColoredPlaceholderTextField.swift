//
//  ColoredPlaceholderTextField.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 7/9/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

@IBDesignable class ColoredPlaceholderTextField: UITextField
{
	@IBInspectable var placeholderColor: UIColor = UIColor.lightGray
	
	override func drawPlaceholder(in rect: CGRect)
	{
		guard let lPlaceholder = self.placeholder else
		{
			return
		}

		var lFont = self.font

		if lFont == nil
		{
			lFont = UIFont.systemFont(ofSize: 16)
		}

		let lParagraphStyle: NSMutableParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
		lParagraphStyle.alignment = self.textAlignment

		let lAttributes: [NSAttributedString.Key: Any] = [
			.font: lFont!,
			.paragraphStyle: lParagraphStyle,
			.foregroundColor: placeholderColor
		]

		let lBounds = lPlaceholder.size(withAttributes: lAttributes)

		if lBounds.width > rect.size.width
		{
			lPlaceholder.draw(in: rect, withAttributes: lAttributes)
		}
		else
		{
			var lXPos = CGFloat(0.0)

			if self.textAlignment == .center || self.textAlignment == .justified
			{
				lXPos = (rect.size.width / 2.0) - (lBounds.width / 2.0)
			}
			else if self.textAlignment == .right
			{
				lXPos = rect.size.width - lBounds.width
			}

			let lDrawRect = CGRect(x: lXPos,
								   y: (rect.size.height / 2.0) - (lBounds.height / 2.0),
								   width: lBounds.width,
								   height: lBounds.height)

			lPlaceholder.draw(in: lDrawRect, withAttributes: lAttributes)
		}
	}

}
