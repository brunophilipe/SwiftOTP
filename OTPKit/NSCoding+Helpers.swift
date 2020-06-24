//
//  NSCoding+Helpers.swift
//  OTPKit
//
//  Created by Bruno Philipe on 25.06.20.
//  Copyright © 2020 Bruno Philipe. All rights reserved.
//

import Foundation

extension NSCoder {

	func decodeString(forKey key: String) -> String? {
		return decodeObject(of: NSString.self, forKey: key) as String?
	}
}
