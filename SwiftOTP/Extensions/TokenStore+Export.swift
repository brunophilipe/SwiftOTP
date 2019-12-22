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

	func importData(_ data: Data) throws
	{
		guard let fileContents = String(data: data, encoding: .utf8) else
		{
			throw ImportErrors.unknownFileFormat
		}

		for (lineNumber, tokenString) in fileContents.split(separator: "\n").enumerated()
		{
			guard let tokenUrlComponents = URLComponents(string: String(tokenString)) else
			{
				throw ImportErrors.malformedToken(line: lineNumber + 1)
			}

			guard add(tokenUrlComponents) != nil else
			{
				throw ImportErrors.keychainWriteError(line: lineNumber + 1)
			}
		}
	}

	enum ImportErrors: Error
	{
		case unknownFileFormat
		case malformedToken(line: Int)
		case keychainWriteError(line: Int)
	}
}
