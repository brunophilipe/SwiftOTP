//
//  TokensGridView.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 25.06.20.
//  Copyright © 2020 Bruno Philipe. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct TokensGridView: View {
	let dataSource: TokensViewDataSource
	let delegate: TokensViewDelegate

	var body: some View {
		let columns: [GridItem] = [.init(.adaptive(minimum: 150))]
		return ScrollView {
			LazyVGrid(columns: columns) {
				ForEach(0..<dataSource.numberOfTokens, id: \.self) { index in
					TokenView(token: dataSource.token(at: index), delegate: delegate)
				}
			}
			.padding()
		}
		.background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.bottom))
		.navigationBarTitle("Tokens")
	}
}

@available(iOS 14.0, *)
struct TokensGridView_Previews: PreviewProvider, TokensViewDataSource, TokensViewDelegate {

	private let fakeAccounts: [TokenViewModel] = [
		TokenViewModel(account: "abc123", issuer: "ACME, Inc.", label: "john@apple.com"),
		TokenViewModel(account: "abc123", issuer: "ACME, Inc.", label: "john@apple.com"),
		TokenViewModel(account: "abc123", issuer: "ACME, Inc.", label: "john@apple.com"),
		TokenViewModel(account: "abc123", issuer: "ACME, Inc.", label: "john@apple.com"),
		TokenViewModel(account: "abc123", issuer: "ACME, Inc.", label: "john@apple.com"),
		TokenViewModel(account: "abc123", issuer: "ACME, Inc.", label: "john@apple.com"),
		TokenViewModel(account: "abc123", issuer: "ACME, Inc.", label: "john@apple.com"),
		TokenViewModel(account: "abc123", issuer: "ACME, Inc.", label: "john@apple.com")
	]

	var numberOfTokens: Int {
		return fakeAccounts.count
	}

	func token(at index: Int) -> TokenViewModel {
		return fakeAccounts[index]
	}

	func didTapActionsButton(for token: TokenViewModel) {

	}

	func didTapShowButton(for token: TokenViewModel) {

	}

	func didTapCopyButton(for token: TokenViewModel) {

	}

	static var previews: some View {
		let dataSourceDelegate = TokensGridView_Previews()
		return NavigationView() {
			TokensGridView(dataSource: dataSourceDelegate, delegate: dataSourceDelegate)
		}.previewDevice("iPhone XS").accentColor(.orange)
	}
}
