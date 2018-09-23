//
//  IndexPath+TupleValue.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 23/9/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

extension IndexPath
{
	var tableRowTupleValue: (Int, Int)
	{
		return (section, row)
	}
}
