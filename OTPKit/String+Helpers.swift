//
//  String+Helpers.swift
//  OTPKit
//
//  Created by Bruno Philipe on 28.06.20.
//  Copyright © 2020 Bruno Philipe. All rights reserved.
//

import Foundation

public extension String {

	func dividedIntoClusters(of length: Int? = nil, forSpeech: Bool = false) -> String {
		var string = self
		let count = string.count
		var clusters = [String.SubSequence]()

		func makeClusters(of length: Int) {
			for _ in 0..<(count / length) {
				clusters.append(string.prefix(length))
				string = String(string.dropFirst(length))
			}
		}

		if let length = length {
			makeClusters(of: length)
		}
		else if count > 4, count % 4 == 0 {
			makeClusters(of: 4)
		}
		else if count > 3, count % 3 == 0 {
			makeClusters(of: 3)
		}
		else if count > 2, count % 2 == 0 {
			makeClusters(of: 2)
		}
		else {
			clusters.append(string.prefix(count))
		}

		if forSpeech {
			return clusters.map({ String($0).intelacingCharactersWithSpaces }).joined(separator: ", ")
		} else {
			return clusters.joined(separator: " ")
		}
	}

	var intelacingCharactersWithSpaces: String
	{
		return map({ String($0) }).joined(separator: " ")
	}
}
