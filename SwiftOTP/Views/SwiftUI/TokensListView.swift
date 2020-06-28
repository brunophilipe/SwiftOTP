//
//  TokensListView.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 25.06.20.
//  Copyright © 2020 Bruno Philipe. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct TokensListView: View {
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

private struct TokenView: View {
	let token: TokenViewModel
	let delegate: TokensViewDelegate

	var body: some View {
		VStack(spacing: 0) {
			HStack {
				VStack(alignment: .leading) {
					Text(token.issuer).font(.headline).frame(maxWidth: .infinity, alignment: .leading)
					Text(token.label).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
				}
			}
			.padding([.leading, .trailing, .top, .bottom], 10)


			HStack(alignment: .center, spacing: 2) {
				Button(action: { delegate.didTapActionsButton(for: token) }, imageName: "ellipsis")
				Button(action: { delegate.didTapShowButton(for: token) }, imageName: "eye.fill")
				Button(action: { delegate.didTapCopyButton(for: token) }, imageName: "arrow.right.doc.on.clipboard")
			}
			.font(.headline)
		}
		.background(Color(.secondarySystemGroupedBackground).edgesIgnoringSafeArea(.bottom))
		.cornerRadius(10)
		.shadow(color: Color(UIColor.black.withAlphaComponent(0.1)), radius: 4, y: 4)
	}

	struct Button: View {
		let action: () -> Void
		let imageName: String

		var body: some View {
			SwiftUI.Button(action: action, label: {
				Image(systemName: imageName).padding([.top, .bottom], 8)
			})
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color(.tertiarySystemGroupedBackground))
		}
	}
}

@available(iOS 14.0, *)
struct TokensListView_Previews: PreviewProvider, TokensViewDataSource, TokensViewDelegate {

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
		let dataSourceDelegate = TokensListView_Previews()
		return NavigationView() {
			TokensListView(dataSource: dataSourceDelegate, delegate: dataSourceDelegate)
		}.previewDevice("iPhone XS").accentColor(.orange)
	}
}
