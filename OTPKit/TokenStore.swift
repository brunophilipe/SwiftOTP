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

	@objc(_TokenOrder) fileprivate final class TokenOrder : NSObject, KeychainStorable
	{
		static let store = KeychainStore<TokenOrder>()
		let array: NSMutableArray
		let account: String

		init(storeUUID: UUID, keychainGroupIdentifier: String? = nil)
		{
			array = NSMutableArray()
			account = storeUUID.uuidString

			super.init()
		}

		@objc init?(coder aDecoder: NSCoder)
		{
			account = aDecoder.decodeObject(forKey: "account") as! String
			array = aDecoder.decodeObject(forKey: "array") as! NSMutableArray
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
				keys.remove(at: keys.index(of: key)!)
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
		var ord: TokenOrder
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
		if let ord = TokenOrder.store.load(accountUUID.uuidString), let account = ord.array.object(at: index) as? String
		{
			ord.array.removeObject(at: index)

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
		if let ord = TokenOrder.store.load(accountUUID.uuidString)
		{
			return erase(index: ord.array.index(of: token.account))
		}

		return false
	}

	/// It a valid index is provided (index < `count`), loads the token at the provided index.
	open func load(_ index: Int) -> Token?
	{
		if let ord = TokenOrder.store.load(accountUUID.uuidString), let account = ord.array.object(at: index) as? String
		{
			return Token.store.load(account)
		}

		return nil
	}

	/// If a token with a provided UUID account exists in the receiver, returns it.
	open func load(_ account: String) -> Token?
	{
		return Token.store.load(account)
	}

	/// If the provided token is present in the receiver storage, returns its index.
	open func index(of token: Token) -> Int?
	{
		return index(of: token.account)
	}

	/// If a token with the provided token UUID account is present in the receiver storage, returns its index.
	open func index(of tokenAccount: String) -> Int?
	{
		if let ord = TokenOrder.store.load(accountUUID.uuidString)
		{
			let index = ord.array.indexOfObject(passingTest: { (object, _, _) -> Bool in
				return (object as? String) == tokenAccount
			})

			if index == NSNotFound
			{
				return nil
			}

			return index
		}

		return nil
	}

	/// Repositions the token at index `from` into index `to`, and shifts all other tokens up/down to fill the gap.
	@discardableResult open func move(_ from: Int, to: Int) -> Bool
	{
		if let ord = TokenOrder.store.load(accountUUID.uuidString), let id = ord.array.object(at: from) as? String
		{
			ord.array.removeObject(at: from)
			ord.array.insert(id, at: to)

			return TokenOrder.store.save(ord)
		}

		return false
	}
}
