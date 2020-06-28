//
//  TokenViewModel.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 27.06.20.
//  Copyright © 2020 Bruno Philipe. All rights reserved.
//

import Foundation
import Combine
import OTPKit

struct TokenViewModel: Identifiable {
	let account: String
	let issuer: String
	let label: String

	var id: String {
		return account
	}
}

extension Token: Identifiable {
	public var id: String {
		return account
	}
}
