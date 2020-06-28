//
//  TokenView.swift
//  SwiftOTP
//
//  Created by Bruno Philipe on 28.06.20.
//  Copyright © 2020 Bruno Philipe. All rights reserved.
//

import SwiftUI

struct TokenView: View {
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

	private struct Button: View {
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

struct TokenView_Previews: PreviewProvider, TokensViewDelegate {

	func didTapActionsButton(for token: TokenViewModel) {

	}

	func didTapShowButton(for token: TokenViewModel) {

	}

	func didTapCopyButton(for token: TokenViewModel) {

	}


	static var previews: some View {
		TokenView(token: TokenViewModel(account: "abc123", issuer: "Democorp", label: "john@demo.com"),
				  delegate: TokenView_Previews())
			.frame(width: 160.0, height: 94.0)
	}
}
