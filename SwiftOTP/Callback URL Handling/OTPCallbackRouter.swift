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

		register(action: "fetch-code", actionHandler: handleFetchCode)
	}

	private func handleFetchCode(_ parameters: Parameters,
								 _ successHandler: SuccessCallback,
								 _ failureHandler: FailureCallback,
								 _ cancelHandler: CancelCallback)
	{
		// First test if this is an authorized request.
		if let authorizedFetchRequest = AuthorizedCodeFetchRequest(parameters: parameters)
		{
			// Perform code fetch
			return
		}

		// Check if all needed parameters are resent.
		guard let authorizationRequest = AuthorizationRequest(parameters: parameters) else
		{
			failureHandler(CallbackError.missingParameters)
			return
		}

		typealias Context = TokensViewController.AuthorizeIntegrationContext
		let authorizationContext = Context(authorizationRequest: authorizationRequest,
										   successHandler: { },
										   failureHandler: { })

		successHandler(["code": "102030"])
	}

	class AuthorizationRequest
	{
		/// A unique identifier of this integration client, possibly also unique by detail (account).
		let clientId: UUID

		/// A human-readable identifier of the integrated app, possiblty the app's name.
		let clientApp: String

		/// An optional detail of this integration, for example an email address of the user's account.
		let clientDetail: String?

		init?(parameters: [String: String])
		{
			guard
				let clientId = parameters["client_id"],
				let clientUUID = UUID(uuidString: clientId),
				let clientApp = parameters["client_app"]
				else
			{
				return nil
			}

			let clientDetail = parameters["client_detail"]

			self.clientId = clientUUID
			self.clientApp = clientApp
			self.clientDetail = clientDetail
		}
	}

	class AuthorizedCodeFetchRequest: AuthorizationRequest
	{
		/// An opaque hash that identifies a previous authorization associated with this client id UUID.
		let clientSecret: String?

		override init?(parameters: [String : String])
		{
			guard let clientSecret = parameters["client_secret"] else
			{
				return nil
			}

			self.clientSecret = clientSecret
			
			super.init(parameters: parameters)
		}
	}
}

enum CallbackError: Int, FailureCallbackError
{
	case unknownIdentifier = 1
	case failedComputingCode
	case missingParameters

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

		case .missingParameters:
			return "Missing either client_id and/or client_app parameters."
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
