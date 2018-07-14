//
//  PreferencesViewController.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 14/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

class PreferencesViewController: UITableViewController
{
    override func viewDidLoad()
	{
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		if navigationController?.isToolbarHidden == false
		{
			navigationController?.setToolbarHidden(true, animated: animated)
		}
	}
    
	@IBAction func done(_ sender: Any?)
	{
		dismiss(animated: true)
	}
}
