//
//  UIViewController+Segues.swift
//  Journal
//
//  Created by Bruno Philipe on 30/6/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

/// A Segue is a type-safe form of a UI segue.
protocol Segue
{
	/// The identifier of this segue
	var identifier: String { get }
}

extension UIViewController
{
	/// Perform a type-safe segue, optionally proviing a sender object.
	func performSegue(_ segue: Segue, sender: Any?)
	{
		self.performSegue(withIdentifier: segue.identifier, sender: sender)
	}
}

/// Automatically synthesizes identifiers from the raw value of entities that conform
/// to both RawRepresentable and Segue
extension Segue where Self: RawRepresentable, Self.RawValue == String
{
	var identifier: String
	{
		return rawValue
	}
}
