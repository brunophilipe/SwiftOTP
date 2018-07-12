//
//  UIViewController+LocalAuthentication.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 12/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit
import LocalAuthentication

extension UIViewController
{
	enum SecurityContextResult
	{
		/// Successfully entered security context.
		case success

		/// Failed entering security context. Includes error if present.
		case error(NSError?)

		/// No security context available because passcode is not set.
		case disabled

		/// Returns true iff this error is caused by any cancelation of the authentication context.
		static func isCanceledError(_ error: NSError) -> Bool
		{
			guard let laErrorCode = LAError.Code(rawValue: error.code) else
			{
				return false
			}

			return [LAError.Code.appCancel, .userCancel, .systemCancel].contains(laErrorCode)
		}
	}

	/// Attempts entering a locally authenticated context (using biometrics or the device passcode).
	///
	/// The completion block is always called on the main queue.
	///
	/// - Parameters:
	///   - reason: A user-presented string that explains why authentiction is required.
	///   - completion: The block called with the result of the operation. See SecurityContextResult.
	func enterSecurityContext(reason: String, completion: @escaping (SecurityContextResult) -> Void)
	{
		let laContext = LAContext()
		var authError: NSError? = nil

		guard laContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) else
		{
			DispatchQueue.main.async(execute: { completion(.disabled) })
			laContext.invalidate()
			return
		}

		laContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
			{
				success, error in

				DispatchQueue.main.async(execute: { completion(success ? .success : .error(error as NSError?))})
				laContext.invalidate()

				if let error = error
				{
					NSLog("Failed authenticating device owner: \(error)")
				}
			}
	}
}
