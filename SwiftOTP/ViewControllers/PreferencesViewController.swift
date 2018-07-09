//
//  PreferencesViewController.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 9/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

class PreferencesViewController: UITableViewController
{
	@IBOutlet var intentsPutCodeInClipboardSwitch: UISwitch!
	@IBOutlet var allowClipboardHandoffSwitch: UISwitch!

    override func viewDidLoad()
	{
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		intentsPutCodeInClipboardSwitch.isOn = Preferences.instance.intentsPutCodeInClipboard
		allowClipboardHandoffSwitch.isOn = Preferences.instance.allowClipboardHandoff
    }

	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
	{
		if indexPath.section == 0
		{
			let isSelected = Preferences.instance.clipboardExpirationLength.indexPath == indexPath
			cell.accessoryType = isSelected ? .checkmark : .none
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		if indexPath.section == 0, let clipboardExpiration = ClipboardExpiration(indexPath: indexPath)
		{
			let oldSelectedIndexPath = Preferences.instance.clipboardExpirationLength.indexPath
			Preferences.instance.clipboardExpirationLength = clipboardExpiration
			tableView.cellForRow(at: oldSelectedIndexPath)?.accessoryType = .none
			tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
		}

		tableView.deselectRow(at: indexPath, animated: true)
	}

	@IBAction func done(_ sender: Any)
	{
		dismiss(animated: true)
	}

	@IBAction func valueChanged(_ sender: Any)
	{
		if let senderSwitch = sender as? UISwitch
		{
			switch senderSwitch
			{
			case intentsPutCodeInClipboardSwitch:
				Preferences.instance.intentsPutCodeInClipboard = senderSwitch.isOn

			case allowClipboardHandoffSwitch:
				Preferences.instance.allowClipboardHandoff = senderSwitch.isOn

			default:
				break
			}
		}
	}
}

extension ClipboardExpiration
{
	var indexPath: IndexPath
	{
		return IndexPath(row: rawValue, section: 0)
	}

	init?(indexPath: IndexPath)
	{
		self.init(rawValue: indexPath.row)
	}
}
