//
//  UIView+ShowHide.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 9/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

extension UIView
{
	func animatedShow(withDuration duration: TimeInterval = 0.2)
	{
		alpha = 0.0
		UIView.animate(withDuration: duration, delay: 0.0, options: [.beginFromCurrentState], animations: {
			self.alpha = 1.0
		})
	}

	func animatedHide(withDuration duration: TimeInterval = 0.2, completion: ((Bool) -> Void)? = nil)
	{
		alpha = 1.0
		UIView.animate(withDuration: duration, delay: 0.0, options: [.beginFromCurrentState], animations: {
			self.alpha = 0.0
		}, completion: completion)
	}

	func animatedHideAndRemoveFromSuperview(withDuration duration: TimeInterval = 0.2)
	{
		animatedHide(withDuration: duration, completion: { _ in self.removeFromSuperview() })
	}
}
