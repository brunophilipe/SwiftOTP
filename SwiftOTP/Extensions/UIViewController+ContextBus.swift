//
//  UIViewController+ContextBus.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 8/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

@objc extension UIViewController
{
	/// Broadcasts the provided context object to all of this view controlller's children.
	@objc func broadcast(_ context: Any)
	{
		children.forEach({ $0.broadcast(context) })
	}
}
