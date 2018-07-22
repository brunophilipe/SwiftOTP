//
//  OTPCallbackRouter.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 14/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit
import CallbackURLKit
import OTPKit
import CommonCrypto

class OTPCallbackRouter: CallbackRouter
{
	private var didRegisterActions = false

	internal func registerActionsIfNeeded()
	{
		guard !didRegisterActions else
		{
			return
		}

		didRegisterActions = true

		let tokenStore = AppDelegate.shared.tokenStore

		register(action: "fetch-code")
		{
			parameters, successHandler, failureHandler, cancelHandler in

			successHandler(["code": "102030"])
		}
	}
}

enum CallbackError: Int, FailureCallbackError
{
	case unknownIdentifier = 1
	case failedComputingCode

	var code: Int
	{
		return rawValue
	}

	var message: String
	{
		switch self
		{
		case .unknownIdentifier:
			return "Could not find token with provided identifier."

		case .failedComputingCode:
			return "Could not calculate code."
		}
	}
}

private extension TokenStore
{
	func loadToken(with accountHash: String) -> Token?
	{
		for tokenIndex in 0..<count
		{
			if let tokenHash = loadAccount(at: tokenIndex),
				tokenHash.data(using: .ascii)?.sha256Hash == accountHash.data(using: .ascii)
			{
				return load(tokenIndex)
			}
		}

		return nil
	}
}

private extension Data
{
	var sha256Hash: Data
	{
		var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
		withUnsafeBytes {
			_ = CC_SHA256($0, CC_LONG(count), &hash)
		}
		return Data(bytes: hash)
	}
}
