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
	@IBOutlet var appVersionLabel: UILabel!

	override func viewDidLoad()
	{
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		if let bundleHumanVersion = Bundle.main.bundleHumanVersion, let bundleVersion = Bundle.main.bundleVersion
		{
			appVersionLabel.text = "\(bundleHumanVersion) (\(bundleVersion))"
		}
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
