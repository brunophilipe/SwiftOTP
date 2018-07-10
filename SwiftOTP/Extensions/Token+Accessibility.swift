//
//  Token+Accessibility.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 10/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import OTPKit

extension Token
{
	var resolvedIssuer: String
	{
		if let issuer = self.issuer, issuer.count > 0
		{
			return issuer
		}
		else
		{
			return "Empty Issuer"
		}
	}

	var resolvedLabel: String
	{
		if let label = self.label, label.count > 0
		{
			return label
		}
		else
		{
			return "Empty Account"
		}
	}
}
