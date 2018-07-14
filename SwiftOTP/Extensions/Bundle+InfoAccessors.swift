//
//  Bundle+InfoAccessors.swift
//  Kodex
//
//  Created by Bruno Philipe on 15/9/17.
//  Copyright © 2017 Bruno Philipe. All rights reserved.
//

import Foundation

extension Bundle
{
	var bundleVersion: String?
	{
		return object(forInfoDictionaryKey: "CFBundleVersion") as? String
	}

	var bundleHumanVersion: String?
	{
		return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
	}
}
