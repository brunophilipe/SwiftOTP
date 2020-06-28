//
//  AppDelegate.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 7/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit
import OTPKit
import Intents
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	public static let tokenImportUTIs = ["com.brunophilipe.SwiftOTP.tokens", "public.plain-text"]

	public lazy var tokenStore: TokenStore =
		{
			return TokenStore(accountUUID: Constants.tokenStoreUUID,
							  keychainGroupIdentifier: Constants.keychainGroupIdentifier)
		}()

	var window: UIWindow?

	private var userInterfaceState: UserInterfaceState = .loading(pendingContextBroadcasts: [])
	{
		didSet
		{
			switch (oldValue, userInterfaceState)
			{
			case (.loading(let pendingContexts), .ready):
				if let rootViewController = window?.rootViewController
				{
					pendingContexts.forEach({ rootViewController.broadcast($0) })
				}

			default:
				break
			}
		}
	}

	static var shared: AppDelegate
	{
		return UIApplication.shared.delegate! as! AppDelegate
	}

	func mainViewControllerDidAppear()
	{
		if !userInterfaceState.isReady
		{
			userInterfaceState = .ready
		}
	}

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
	{
		// For debugging purposes:
//		INInteraction.deleteAll(completion: nil)
		return true
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool
	{
		if url.scheme == "otpauth",
			let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
		{
			let context = TokensViewController.LoadTokenUrlContext(urlComponents: components)
			broadcastContext(context)
		}

		return false
	}

	// Private stuff

	private func broadcastContext(_ context: Any)
	{
		switch userInterfaceState
		{
		case .ready:
			window?.rootViewController?.broadcast(context)

		case .loading(pendingContextBroadcasts: var pendingBroadcasts):
			pendingBroadcasts.append(context)
			userInterfaceState = .loading(pendingContextBroadcasts: pendingBroadcasts)
		}
	}

	private enum UserInterfaceState
	{
		case loading(pendingContextBroadcasts: [Any]), ready

		var isReady: Bool
		{
			switch self
			{
			case .ready:	return true
			default:		return false
			}
		}
	}
}

extension AppDelegate: NSUserActivityDelegate
{
	func application(_ application: UIApplication,
					 continue userActivity: NSUserActivity,
					 restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
	{
		guard #available(iOS 12.0, *) else
		{
			return false
		}

		if userActivity.activityType == "ViewCodeIntent",
			let intent = userActivity.interaction?.intent as? ViewCodeIntent,
			let account = intent.account
		{
			let context = TokensViewController.ShowCodeFromIntentContext(tokenAccount: account)
			broadcastContext(context)
		}

		return false
	}
}
