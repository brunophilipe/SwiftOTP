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
		debugLog("Lauched intent handler.")

		guard let tokenAccount = intent.account else
		{
			completion(ViewCodeIntentResponse(code: .failure, userActivity: nil))
			debugLog("Bad intent mising account!")
			return
		}

		debugLog("Intent: \(String(describing: intent.issuer)) \(String(describing: intent.label))")

		guard let token = tokenStore.load(tokenAccount) else
		{
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

		completion(ViewCodeIntentResponse.success(otpCode: bestCode.intelacingCharactersWithSpaces))

		debugLog("Did call intent completion handler.")
	}
    
    override func handler(for intent: INIntent) -> Any
	{
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        return self
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
