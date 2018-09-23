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
	public static let tokenImportUTIs = ["com.brunophilipe.SwiftOTP.tokens", "document.plain-text"]

	private let callbackRouter = OTPCallbackRouter(callbackURLScheme: "swiftotp-callback")

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
		callbackRouter.registerActionsIfNeeded()

		// For debugging purposes:
//		INInteraction.deleteAll(completion: nil)
		return true
	}

	func applicationDidEnterBackground(_ application: UIApplication)
	{
		saveContext()
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool
	{
		if url.scheme == "otpauth",
			let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
		{
			let context = TokensViewController.LoadTokenUrlContext(urlComponents: components)
			broadcastContext(context)
		}
		else
		{
			let callbackRouter = self.callbackRouter

			DispatchQueue.main.async
			{
				callbackRouter.registerActionsIfNeeded()
				#if DEBUG
				if !callbackRouter.handleOpen(url: url)
				{
					NSLog("Error parsing open url request")
				}
				#endif
			}
			return true
		}

		return false
	}

	// MARK: - Core Data stack

	lazy var persistentContainer: NSPersistentContainer =
		{
			/*
			The persistent container for the application. This implementation
			creates and returns a container, having loaded the store for the
			application to it. This property is optional since there are legitimate
			error conditions that could cause the creation of the store to fail.
			*/
			let container = NSPersistentContainer(name: "SwiftOTP")
			container.loadPersistentStores()
				{
					(storeDescription, error) in

					if let error = error as NSError?
					{
						// Replace this implementation with code to handle the error appropriately.
						// fatalError() causes the application to generate a crash log and terminate. You should not use
						// this function in a shipping application, although it may be useful during development.

						/*
						Typical reasons for an error here include:
						* The parent directory does not exist, cannot be created, or disallows writing.
						* The persistent store is not accessible, due to permissions or data protection when the device is locked.
						* The device is out of space.
						* The store could not be migrated to the current model version.
						Check the error message to determine what the actual problem was.
						*/
						fatalError("Unresolved error \(error), \(error.userInfo)")
					}
				}

			return container
		}()

	var managedObjectContext: NSManagedObjectContext
	{
		return persistentContainer.viewContext
	}

	// MARK: - Core Data Saving support

	func saveContext()
	{
		let context = persistentContainer.viewContext
		if context.hasChanges
		{
			do
			{
				try context.save()
			}
			catch
			{
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this
				// function in a shipping application, although it may be useful during development.
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}

	// Helpers

	func showTokenPicker(context: AuthorizationViewController.AuthorizeIntegrationContext)
	{
		broadcastContext(context)
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
