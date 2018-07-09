//
//  IntentHandler.swift
//  SwiftOTPIntents
//
//  Created by Bruno Philipe on 9/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import Intents
import OTPKit

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
			NSLog("Bad intent mising account!")
			return
		}

		debugLog("Intent: \(String(describing: intent.issuer)) \(String(describing: intent.label))")

		guard let token = tokenStore.load(tokenAccount) else
		{
			completion(ViewCodeIntentResponse(code: .failure, userActivity: nil))
			NSLog("Bad intent: No token with given account found!")
			return
		}

		debugLog("Good intent! Loading codes…")

		let codes = token.codes

		guard codes.count >= 2 else
		{
			completion(ViewCodeIntentResponse(code: .failure, userActivity: nil))
			NSLog("Bad token! Not enough codes generated.")
			return
		}

		let currentCode = codes.first!
		let nextCode = codes.last!
		let bestCode = (currentCode.to.timeIntervalSinceNow > 5 ? currentCode : nextCode).value

		completion(ViewCodeIntentResponse.success(otpCode: bestCode.intelacingCharactersWithSpaces))

		UIPasteboard.general.setObjects([bestCode], localOnly: true, expirationDate: Date(timeIntervalSinceNow: 2))

		debugLog("Intent handling done with code first digit: \(bestCode.prefix(1)) - Code added to clipboard for 2 seconds.")
	}
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
}

private extension String
{
	var intelacingCharactersWithSpaces: String
	{
		var intelacedString = ""
		forEach({ intelacedString.append("\($0) ") })
		return intelacedString.trimmingCharacters(in: .whitespaces)
	}
}

func debugLog(_ string: String)
{
	#if DEBUG
	NSLog(string)
	#endif
}
