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
import CoreData

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
								 _ successHandler: @escaping SuccessCallback,
								 _ failureHandler: @escaping FailureCallback,
								 _ cancelHandler: @escaping CancelCallback)
	{
		let appDelegate = AppDelegate.shared

		// First test if this is an authorized request.
		if let authorizedFetchRequest = AuthorizedCodeFetchRequest(parameters: parameters)
		{
			let context = appDelegate.managedObjectContext

			do
			{
				// Fetch the integration object
				guard
					let integration = try context.fetch(Integration.fetchRequest(for: authorizedFetchRequest)).first
				else
				{
					failureHandler(CallbackError.unknownIdentifier)
					return
				}

				// Get the token account string, and fetch the best code
				guard
					let tokenAccount = integration.tokenAccount,
					let code = appDelegate.tokenStore.load(tokenAccount)?.bestCode?.value
				else
				{
					failureHandler(CallbackError.failedComputingCode)
					return
				}

				// Return the code
				successHandler(["code": code])
			}
			catch
			{
				failureHandler(CallbackError.internalStorageError)
			}

			return
		}

		// Check if all needed parameters are resent.
		guard let authorizationRequest = AuthorizationRequest(parameters: parameters) else
		{
			failureHandler(CallbackError.missingParameters)
			return
		}

		typealias Context = AuthorizationViewController.AuthorizeIntegrationContext
		let authorizationContext = Context(authorizationRequest: authorizationRequest,
										   failureHandler: { failureHandler(CallbackError.userCanceled) },
										   successHandler:
			{
				tokenAccount in

				guard
					let randomSecret = Data.random(length: 32)?.base64EncodedString(),
					let bestCode = appDelegate.tokenStore.load(tokenAccount)?.bestCode?.value
				else
				{
					failureHandler(CallbackError.internalError)
					return
				}

				// Create the integration object
				let integration = Integration(context: appDelegate.managedObjectContext)
				integration.appName = authorizationRequest.clientApp
				integration.detail = authorizationRequest.clientDetail
				integration.uuid = authorizationRequest.clientId
				integration.secret = randomSecret
				integration.tokenAccount = tokenAccount

				// Save the context
				appDelegate.saveContext()

				// Finalize by sending the data back to the caller app
				successHandler(["code": bestCode, "client_secret": randomSecret])
			})

		appDelegate.showTokenPicker(context: authorizationContext)
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
		let clientSecret: String

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
	case userCanceled
	case failedComputingCode
	case missingParameters
	case internalStorageError
	case internalError

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

		case .userCanceled:
			return "user canceled authorization."

		case .failedComputingCode:
			return "Could not calculate code."

		case .missingParameters:
			return "Missing either client_id and/or client_app parameters."

		case .internalStorageError:
			return "The integrations storage database seems corrupted."

		case .internalError:
			return "Application error: could not generate random numbers."
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

	static func random(length: Int) -> Data?
	{
		var keyData = Data(count: length)
		let result = keyData.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, length, $0) }

		if result == errSecSuccess
		{
			return keyData
		}
		else
		{
			print("Problem generating random bytes")
			return nil
		}
	}
}
