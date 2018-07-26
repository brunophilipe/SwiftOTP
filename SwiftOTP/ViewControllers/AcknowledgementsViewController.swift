//
//  AcknowledgementsViewController.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 26/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit
import AcknowList

class AcknowledgementsViewController: AcknowListViewController
{
    override func viewDidLoad()
	{
        super.viewDidLoad()

    	tableView.backgroundColor = #colorLiteral(red: 0.07289864868, green: 0.07289864868, blue: 0.07289864868, alpha: 1)
		tableView.separatorColor = #colorLiteral(red: 0.1921356022, green: 0.1921699941, blue: 0.1921312809, alpha: 1)
    }

	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
	{
		cell.backgroundColor = #colorLiteral(red: 0.1098284498, green: 0.1097278222, blue: 0.1140929684, alpha: 1)
		cell.textLabel?.textColor = .white
		cell.selectedBackgroundView = UIView()
		cell.selectedBackgroundView?.backgroundColor = #colorLiteral(red: 0.232245788, green: 0.232245788, blue: 0.232245788, alpha: 1)
	}
}
