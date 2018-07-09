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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	var window: UIWindow?

	private var userInterfaceState: UserInterfaceState = .loading(pendingContextBroadcasts: [])
	{
		didSet
		{
			switch (oldValue, userInterfaceState)
			{
			case (.loading(let pendingContexts), .ready):
				if let rootViewController = UIApplication.shared.keyWindow?.rootViewController
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
		// Override point for customization after application launch.

		// For debugging purposes:
//		INInteraction.deleteAll(completion: nil)
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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

	private func broadcastContext(_ context: Any)
	{
		switch userInterfaceState
		{
		case .ready:
			(UIApplication.shared.keyWindow?.rootViewController)?.broadcast(context)

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

