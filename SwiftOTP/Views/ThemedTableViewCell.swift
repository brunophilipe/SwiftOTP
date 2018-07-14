//
//  ThemedTableViewCell.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 14/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

class ThemedTableViewCell: UITableViewCell
{
    override func awakeFromNib()
	{
        super.awakeFromNib()
        // Initialization code

		let selectedBackgroundView = UIView(frame: frame)
		selectedBackgroundView.backgroundColor = #colorLiteral(red: 0.232245788, green: 0.232245788, blue: 0.232245788, alpha: 1)
		self.selectedBackgroundView = selectedBackgroundView
    }
}
