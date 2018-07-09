//
//  Preferences.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 7/9/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

class Preferences: NSObject
{
	private static let suiteName = "group.com.brunophilipe.SwiftOTP"
	private static var sharedInstance: Preferences! = nil

	internal lazy var defaults = UserDefaults(suiteName: Preferences.suiteName) ?? .standard

	/// Initializer declared as private to avoid accidental creation of new instances.
	private override init()
	{
		super.init()
	}

	/// The shared instance of the Preferences class. Do not create individual instances of this class, as this will break KVO.
	@objc
	class var instance: Preferences
	{
		if sharedInstance == nil
		{
			sharedInstance = Preferences()
		}

		return sharedInstance
	}

	// Default helpers

	func number(forKey key: String) -> NSNumber?
	{
		return defaults.object(forKey: key) as? NSNumber
	}
}

extension Preferences // Available preferences
{
	/// How long should the code be left in the clipboard after tapping the "Copy to Clipboard" button.
	@objc dynamic var clipboardExpirationLength: ClipboardExpiration
	{
		get { return number(forKey: #keyPath(clipboardExpirationLength))?.clipboardExpirationValue ?? .thirtySeconds }
		set { defaults.setValue(newValue.numberValue, forKey: #keyPath(clipboardExpirationLength)) }
	}

	/// Whether placing the code can be shared to other iCloud devices via the handoff clipboard.
	@objc dynamic var allowClipboardHandoff: Bool
	{
		get { return number(forKey: #keyPath(allowClipboardHandoff))?.boolValue ?? false }
		set { defaults.setValue(NSNumber(value: newValue), forKey: #keyPath(allowClipboardHandoff)) }
	}

	/// Whether the Siri intents also places the generated code in the clipboard in addition to returning it in the
	/// intent response object.
	@objc dynamic var intentsPutCodeInClipboard: Bool
	{
		get { return number(forKey: #keyPath(intentsPutCodeInClipboard))?.boolValue ?? false }
		set { defaults.setValue(NSNumber(value: newValue), forKey: #keyPath(intentsPutCodeInClipboard)) }
	}
}

@objc enum ClipboardExpiration: Int
{
	case tenSeconds
	case thirtySeconds
	case oneMinute
	case fiveMinutes

	var numberValue: NSNumber
	{
		return NSNumber(value: rawValue)
	}

	var timeIntervalValue: TimeInterval
	{
		switch self
		{
		case .tenSeconds:		return 10
		case .thirtySeconds:	return 30
		case .oneMinute:		return 60
		case .fiveMinutes:		return 60 * 5
		}
	}
}

extension NSNumber
{
	var clipboardExpirationValue: ClipboardExpiration?
	{
		return ClipboardExpiration(rawValue: intValue)
	}
}
