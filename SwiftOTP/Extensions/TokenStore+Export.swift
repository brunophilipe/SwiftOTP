//
//  TokenStore+Export.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 14/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import Foundation
import OTPKit

extension TokenStore
{
	func exportData(for accounts: Set<String>) -> Data?
	{
		guard accounts.count > 0, accounts.count <= count else
		{
			return nil
		}

		return accounts.compactMap({ load($0)?.asUrl?.absoluteString }).joined(separator: "\n").data(using: .utf8)
	}
}
