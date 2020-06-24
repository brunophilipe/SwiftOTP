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

public protocol KeychainStorable : NSObject, NSSecureCoding
{
	static var store: KeychainStore<Self> { get }
	var account: String { get }
}

open class KeychainStore<T: KeychainStorable>
{
	fileprivate let service: String

	/// Set this property to a keychain group identifier use a shared keychain, or set it to
	/// `nil` to use the local keychain. The default value is nil.
	public var keychainGroupIdentifier: String? = nil

	fileprivate func query(_ account: String) -> [String: AnyObject]
	{
		var query = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: account as AnyObject,
			kSecAttrService as String: service as AnyObject
		]

		if let accessGroup = keychainGroupIdentifier
		{
			query[kSecAttrAccessGroup as String] = accessGroup as AnyObject
		}

		return query
	}

	fileprivate func add(_ account: String, _ data: Data, _ locked: Bool = false) -> Bool
	{
		let date = Date()
		var add: [String: AnyObject] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrCreationDate as String: date as AnyObject,
			kSecAttrModificationDate as String: date as AnyObject,
			kSecAttrAccount as String: account as AnyObject,
			kSecAttrService as String: service as AnyObject,
			kSecValueData as String: data as AnyObject,
		]

		if locked
		{
			let sac = SecAccessControlCreateWithFlags(
				kCFAllocatorDefault,
				kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
				.userPresence,
				nil
			)

			add[kSecAttrAccessControl as String] = sac
		}
		else
		{
			add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
		}

		if let accessGroup = keychainGroupIdentifier
		{
			add[kSecAttrAccessGroup as String] = accessGroup as AnyObject
		}

		return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
	}

	open var lockingSupported: Bool
	{
		let id = UUID().uuidString
		if add(id, Data(), true)
		{
			return erase(id)
		}

		return false
	}

	public init()
	{
		service = NSStringFromClass(T.self)
	}

	@discardableResult open func add(_ storable: T, locked: Bool = false) -> Bool
	{
		guard let data = try? NSKeyedArchiver.archivedData(withRootObject: storable, requiringSecureCoding: true) else {
			return false
		}

		return add(storable.account, data, locked && lockingSupported)
	}

	@discardableResult open func save(_ storable: T) -> Bool
	{
		guard let data = try? NSKeyedArchiver.archivedData(withRootObject: storable, requiringSecureCoding: true) else {
			return false
		}

		let update: [String: AnyObject] = [
			kSecValueData as String: data as AnyObject,
			kSecAttrModificationDate as String: Date() as AnyObject,
		]

		return SecItemUpdate(query(storable.account) as CFDictionary, update as CFDictionary) == errSecSuccess
	}

	open func load(_ account: String) -> T?
	{
		var dict = query(account)
		dict[kSecReturnData as String] = true as AnyObject

		var output: AnyObject?
		let status = SecItemCopyMatching(dict as CFDictionary, &output)
		if status == errSecSuccess {
			if let data = output as? Data {
				if let storable = try? NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: data) {
					return storable
				}
			}
		}

		return nil
	}

	@discardableResult open func erase(_ storable: T) -> Bool
	{
		return erase(storable.account)
	}

	@discardableResult open func erase(_ account: String) -> Bool
	{
		return SecItemDelete(query(account) as CFDictionary) == errSecSuccess
	}
}
