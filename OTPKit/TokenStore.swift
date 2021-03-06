//
// FreeOTP
//
// Authors: Nathaniel McCallum <npmccallum@redhat.com>
//
// Copyright (C) 2015  Nathaniel McCallum, Red Hat
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//	  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import Security

open class TokenStore : NSObject
{
	private let accountUUID: UUID

	@objc(_TokenOrder) fileprivate final class TokenOrder: NSObject, KeychainStorable
	{
		static var supportsSecureCoding: Bool {
			return true
		}

		static let store = KeychainStore<TokenOrder>()
		var array: [String]
		let account: String

		init(storeUUID: UUID, keychainGroupIdentifier: String? = nil)
		{
			array = [String]()
			account = storeUUID.uuidString

			super.init()
		}

		@objc init?(coder aDecoder: NSCoder)
		{
			if let account = aDecoder.decodeString(forKey: "account"),
			   let array = aDecoder.decodeObject(of: NSArray.self, forKey: "array") as? [String] {
				self.account = account
				self.array = array
			} else {
				return nil
			}
		}

		@objc fileprivate func encode(with aCoder: NSCoder)
		{
			aCoder.encode(array, forKey: "array")
			aCoder.encode(account, forKey: "account")
		}
	}

	/// Returns the number of tokens registered with the receiver store.
	open var count: Int
	{
		if let ord = TokenOrder.store.load(accountUUID.uuidString)
		{
			return ord.array.count
		}

		return 0
	}

	/// Initializes the token storage with a global account UUID. This UUID needs to be consistent between
	/// instantiations of the TokenStore, so that the same token objects are available between instances.
	public init(accountUUID: UUID, keychainGroupIdentifier: String? = nil)
	{
		self.accountUUID = accountUUID

		super.init()

		TokenOrder.store.keychainGroupIdentifier = keychainGroupIdentifier

		// Migrate UserDefaults tokens to Keyring tokens
			let def = UserDefaults.standard
		if var keys = def.stringArray(forKey: "tokenOrder")
		{
			var remove = [String]()

			for key in keys.reversed()
			{
				if let url = def.string(forKey: key), let urlc = URLComponents(string: url), add(urlc) != nil
				{
					def.removeObject(forKey: key)
					remove.append(key)
				}
			}

			for key in remove
			{
				keys.remove(at: keys.firstIndex(of: key)!)
			}

			if keys.count == 0
			{
				def.removeObject(forKey: "tokenOrder")
			}
		}
	}

	/// Add a token to the receiver's storage by parsing the provided `URLComponents` object.
	@discardableResult open func add(_ urlc: URLComponents) -> Token?
	{
		let ord: TokenOrder
		if let a = TokenOrder.store.load(accountUUID.uuidString)
		{
			ord = a
		}
		else
		{
			ord = TokenOrder(storeUUID: accountUUID)
			if !TokenOrder.store.add(ord)
			{
				return nil
			}
		}

		if let otp = OTP(urlc: urlc)
		{
			if let token = Token(otp: otp, urlc: urlc)
			{
				ord.array.insert(otp.account, at: 0)
				if OTP.store.add(otp, locked: token.locked)
				{
					if Token.store.add(token)
					{
						if TokenOrder.store.save(ord)
						{
							return token
						}
						else
						{
							Token.store.erase(token)
							OTP.store.erase(otp)
						}
					}
					else
					{
						OTP.store.erase(otp)
					}
				}
			}
		}

		return nil
	}

	/// If a valid index is provided (`index` < `count`), removes the token at `index` from the receiver's storage.
	@discardableResult open func erase(index: Int) -> Bool
	{
		if let ord = TokenOrder.store.load(accountUUID.uuidString), index < ord.array.count
		{
			let account = ord.array[index]
			ord.array.remove(at: index)

			if TokenOrder.store.save(ord)
			{
				Token.store.erase(account)
				OTP.store.erase(account)
				return true
			}
		}

		return false
	}

	/// Erases the provided token from the receiver's storage, if it is present.
	@discardableResult open func erase(token: Token) -> Bool
	{
		if let ord = TokenOrder.store.load(accountUUID.uuidString), let index = ord.array.firstIndex(of: token.account)
		{
			return erase(index: index)
		}

		return false
	}

	/// Erases **all** stored tokens.
	open func eraseAll() {
		for _ in 0..<count {
			erase(index: 0)
		}
	}

	/// It a valid index is provided (index < `count`), loads the token at the provided index.
	open func load(_ index: Int) -> Token?
	{
		if let ord = TokenOrder.store.load(accountUUID.uuidString), index < ord.array.count
		{
			return Token.store.load(ord.array[index])
		}

		return nil
	}

	/// If a token with a provided UUID account exists in the receiver, returns it.
	open func load(_ account: String) -> Token?
	{
		return Token.store.load(account)
	}

	/// Returns only the account of the token at the provided index.
	open func loadAccount(at index: Int) -> String?
	{
		if let ord = TokenOrder.store.load(accountUUID.uuidString), index < ord.array.count
		{
			return ord.array[index]
		}

		return nil
	}

	/// If the provided token is present in the receiver storage, returns its index.
	open func index(of token: Token) -> Int?
	{
		return index(of: token.account)
	}

	/// If a token with the provided token UUID account is present in the receiver storage, returns its index.
	open func index(of tokenAccount: String) -> Int?
	{
		if let ord = TokenOrder.store.load(accountUUID.uuidString), let index = ord.array.firstIndex(of: tokenAccount)
		{
			return index
		}

		return nil
	}

	/// Repositions the token at index `from` into index `to`, and shifts all other tokens up/down to fill the gap.
	@discardableResult open func move(_ from: Int, to: Int) -> Bool
	{
		if let ord = TokenOrder.store.load(accountUUID.uuidString), from < ord.array.count
		{
			let id = ord.array[from]
			ord.array.remove(at: from)
			ord.array.insert(id, at: to)

			return TokenOrder.store.save(ord)
		}

		return false
	}

	public func sortTokens<C: Comparable & Hashable>(by keyPath: KeyPath<Token, C?>) -> CollectionDifference<Int>? {
		return sortTokens(by: keyPath, ascending: true)
	}

	private func sortTokens<C: Comparable & Hashable>(by keyPath: KeyPath<Token, C?>, ascending: Bool) -> CollectionDifference<Int>? {

		guard let order = TokenOrder.store.load(accountUUID.uuidString) else {
			return nil
		}

		var tokensMap: [String: Token] = [:]

		enumerateTokens { (_, token) in
			tokensMap[token.account] = token
		}

		func tieBreaker(token1: Token, token2: Token) -> Bool {
			if token1[keyPath: keyPath] as? String == token1.issuer {
				return token1.account < token2.account
			} else {
				return token1.issuer < token2.issuer
			}
		}

		let unsortedAccounts = order.array
		var sortedAccounts = unsortedAccounts.sorted(by: {
			switch (tokensMap[$0]?[keyPath: keyPath], tokensMap[$1]?[keyPath: keyPath]) {
			case let (.some(value1), .some(value2)) where value1 == value2:
				return tieBreaker(token1: tokensMap[$0]!, token2: tokensMap[$1]!)
			case let (.some(value1), .some(value2)):
				return value1 < value2
			case (.some, .none):
				return false
			case (.none, .some), (.none, .none):
				return true
			}
		})

		if ascending == false {
			sortedAccounts.reverse()
		}

		if sortedAccounts == unsortedAccounts, ascending {
			return sortTokens(by: keyPath, ascending: false)
		}

		order.array = sortedAccounts

		guard TokenOrder.store.save(order) else {
			return nil
		}

		let unsortedIndices = Array(0..<unsortedAccounts.count)
		let sortedIndices = sortedAccounts.compactMap({ unsortedAccounts.firstIndex(of: $0) })

		assert(unsortedIndices.count == sortedIndices.count)

		return sortedIndices.difference(from: unsortedIndices)
	}

	open func enumerateTokens(using block: (Int, Token) -> Void) {
		for index in 0..<count {
			guard let token = load(index) else { continue }
			block(index, token)
		}
	}
}
