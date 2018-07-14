//
//  FileManager+Helpers.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 14/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import Foundation

extension FileManager
{
	var cachesDirectoryUrl: URL?
	{
		return try? url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
	}
}
