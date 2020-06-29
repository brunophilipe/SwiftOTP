//
//  UIViewController+Menus.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 29.06.20.
//  Copyright © 2020 Bruno Philipe. All rights reserved.
//

import UIKit

extension UIViewController {

	func setUpMenu(for barButtonItem: UIBarButtonItem, actions: [GenericAction]) {
		if #available(iOS 14.0, *) {
			setUpContextMenu(for: barButtonItem, actions: actions)
		} else {
			setUpActionSheet(for: barButtonItem, actions: actions)
		}
	}

	@available(iOS 14.0, *)
	private func setUpContextMenu(for barButtonItem: UIBarButtonItem, actions: [GenericAction]) {
		barButtonItem.menu = UIMenu(title: "", children: actions.map({ $0.asAction() }))
		barButtonItem.action = nil
	}

	private func setUpActionSheet(for barButtonItem: UIBarButtonItem, actions: [GenericAction]) {
		let handler = ActionSheetActionHandler(actions: actions, viewController: self)
		objc_setAssociatedObject(barButtonItem, "SwiftOTP.ActionSheetAsMenuHandler", handler, .OBJC_ASSOCIATION_RETAIN)

		barButtonItem.action = #selector(ActionSheetActionHandler.didTapActionSheetTriggerButton(_:))
		barButtonItem.target = handler
	}

	struct GenericAction {
		let title: String
		let handler: () -> Void

		func asAlertAction() -> UIAlertAction {
			return UIAlertAction(title: title, style: .default, handler: { _ in handler() })
		}

		func asAction() -> UIAction {
			return UIAction(title: title, handler: { _ in handler() })
		}
	}
}

private class ActionSheetActionHandler: NSObject {
	let actions: [UIViewController.GenericAction]

	unowned let viewController: UIViewController

	init(actions: [UIViewController.GenericAction], viewController: UIViewController) {
		self.actions = actions
		self.viewController = viewController
		super.init()
	}

	@objc
	func didTapActionSheetTriggerButton(_ sender: Any?) {
		let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		actions.forEach({ actionSheet.addAction($0.asAlertAction()) })
		actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

		viewController.present(actionSheet, animated: true)
	}
}
