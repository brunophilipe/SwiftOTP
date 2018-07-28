//
//  Integration+FetchRequests.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 28/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import Foundation
import CoreData

extension Integration
{
	static func fetchRequest(for authorizedRequest: OTPCallbackRouter.AuthorizedCodeFetchRequest) -> NSFetchRequest<Integration>
	{
		let clientDetail = authorizedRequest.clientDetail

		let predicates: [String] = [
			"uuid like \"\(authorizedRequest.clientId.uuidString)\"",
			"appName like \"\(authorizedRequest.clientApp)\"",
			"secret like \"\(authorizedRequest.clientSecret)\"",
			clientDetail != nil ? "appDetail like \"\(clientDetail!)\"" : "appDetail == nil",
		]

		let integrationRequest: NSFetchRequest<Integration> = Integration.fetchRequest()
		integrationRequest.predicate = NSPredicate(format: predicates.joined(separator: " AND "))
		integrationRequest.fetchLimit = 1
		return integrationRequest
	}
}
