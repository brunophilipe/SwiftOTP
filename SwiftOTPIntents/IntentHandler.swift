//
//  IntentHandler.swift
//  SwiftOTPIntents
//
//  Created by Bruno Philipe on 9/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import Intents
import OTPKit

@available(iOSApplicationExtension 12.0, *)
class IntentHandler: INExtension, ViewCodeIntentHandling
{
	private let tokenStore = TokenStore(accountUUID: Constants.tokenStoreUUID,
										keychainGroupIdentifier: Constants.keychainGroupIdentifier)

	func handle(intent: ViewCodeIntent, completion: @escaping (ViewCodeIntentResponse) -> Void)
	{
		let token: Token

		debugLog("Lauched intent handler.")
		debugLog("Intent: \(String(describing: intent.issuer)) \(String(describing: intent.label))")

		if let tokenAccount = intent.account, let tokenForAccount = tokenStore.load(tokenAccount) {
			token = tokenForAccount
		} else if let issuer = intent.issuer {
			let tokens = resolveTokens(fromIssuer: issuer)

			guard tokens.count == 1, let resolvedToken = tokens.first else {
				completion(ViewCodeIntentResponse(code: .failure, userActivity: nil))
				debugLog("Bad intent: No unique match for given issuer ‘\(issuer)’! Results count: \(tokens.count)")
				return
			}

			token = resolvedToken
		} else {
			completion(ViewCodeIntentResponse(code: .failure, userActivity: nil))
			debugLog("Bad intent: No token with given account found!")
			return
		}

		debugLog("Good intent! Loading codes…")

		let codes = token.codes

		guard codes.count >= 2 else
		{
			completion(ViewCodeIntentResponse(code: .failure, userActivity: nil))
			debugLog("Bad token! Not enough codes generated.")
			return
		}

		let currentCode = codes.first!
		let nextCode = codes.last!
		let bestCode = (currentCode.to.timeIntervalSinceNow > 5 ? currentCode : nextCode).value

		if Preferences.instance.intentsPutCodeInClipboard
		{
			UIPasteboard.general.setObjects([bestCode], localOnly: true, expirationDate: Date(timeIntervalSinceNow: 3))
			debugLog("Code first digit: \(bestCode.prefix(1)) - Code added to clipboard for 3 seconds.")
		}
		else
		{
			debugLog("Code first digit: \(bestCode.prefix(1)) - Did NOT put code in clipboard.")
		}

		completion(ViewCodeIntentResponse.success(otpCodeForSpeech: bestCode.intelacingCharactersWithSpaces,
												  otpCode: bestCode))

		debugLog("Did call intent completion handler.")
	}

	override func handler(for intent: INIntent) -> Any
	{
		// This is the default implementation.  If you want different objects to handle different intents,
		// you can override this and return the handler you want for that particular intent.
		return self
	}

	func resolveIssuer(for intent: ViewCodeIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		// If we have an account id set, try to use that
		if let account = intent.account {
			if let token = tokenStore.load(account) {
				completion(.success(with: token.issuer))
				return
			}
		}

		// If issuer string was provided, try to look for matches
		if let issuer = intent.issuer {
			let matches = resolveTokens(fromIssuer: issuer)

			if matches.isEmpty {
				// None found
				completion(.confirmationRequired(with: issuer))
			} else if matches.count == 1, let resolvedIssuer = matches.first?.issuer {
				// One found. Success
				completion(.success(with: resolvedIssuer))
			} else {
				// Many found. Ask user to pick one
				completion(.disambiguation(with: matches.map({ $0.issuer })))
			}

			return
		}

		// Nothing found.
		completion(.disambiguation(with: resolveTokens(fromIssuer: "").compactMap({ $0.issuer })))
	}

	func provideIssuerOptionsCollection(for intent: ViewCodeIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
		let matches = resolveTokens(fromIssuer: intent.issuer ?? "")

		if matches.isEmpty {
			// None found
			completion(nil, IssuerProviderError.noneFound)
		} else {
			// Many found. Ask user to pick one
			completion(.init(items: matches.map({ $0.issuer as NSString })), nil)
		}
	}

	private func resolveTokens(fromIssuer issuer: String) -> [Token] {
		var matches = [Token]()

		tokenStore.enumerateTokens { (index, token) in
			if issuer.isEmpty || token.issuer.lowercased().contains(issuer.lowercased()) {
				matches.append(token)
			}
		}

		return matches
	}

	enum IssuerProviderError: LocalizedError {
		case noneFound

		var errorDescription: String? {
			switch self {
			case .noneFound:
				return "No matches found."
			}
		}
	}
}

private extension String
{
	var intelacingCharactersWithSpaces: String
	{
		return map({ String($0) }).joined(separator: " ")
	}
}

func debugLog(_ string: String)
{
	#if DEBUG
	NSLog(string)
	#endif
}
