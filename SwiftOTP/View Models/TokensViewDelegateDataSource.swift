//
//  TokensViewDelegateDataSource.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 27.06.20.
//  Copyright © 2020 Bruno Philipe. All rights reserved.
//

import Foundation

protocol TokensViewDataSource {
	var numberOfTokens: Int { get }
	func token(at index: Int) -> TokenViewModel
}

protocol TokensViewDelegate {
	func didTapActionsButton(for token: TokenViewModel)
	func didTapShowButton(for token: TokenViewModel)
	func didTapCopyButton(for token: TokenViewModel)
}
