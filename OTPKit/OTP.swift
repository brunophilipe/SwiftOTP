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

import SwiftBase32
import CommonCrypto
import Foundation

public final class OTP : NSObject, KeychainStorable
{
	public static let store = KeychainStore<OTP>()
	public let account: String

	fileprivate var algo: Int = Int(kCCHmacAlgSHA1)
	fileprivate var size: Int = Int(CC_SHA1_DIGEST_LENGTH)
	fileprivate var secret: Data = Data()
	fileprivate var digits: Int = 6

	public init?(urlc: URLComponents)
	{
		account = UUID().uuidString
		super.init()

		if let query = urlc.queryItems
		{
			for item: URLQueryItem in query
			{
				guard item.value != nil else
				{
					continue
				}

				switch item.name.lowercased()
				{
				case "secret":
					guard let decodedSecret = item.value?.base32DecodedData else
					{
						return nil
					}
					secret = decodedSecret

				case "algorithm":
					switch item.value!.lowercased()
					{
					case "md5":
						algo = Int(kCCHmacAlgMD5)
						size = Int(CC_MD5_DIGEST_LENGTH)
					case "sha1":
						algo = Int(kCCHmacAlgSHA1)
						size = Int(CC_SHA1_DIGEST_LENGTH)
					case "sha224":
						algo = Int(kCCHmacAlgSHA224)
						size = Int(CC_SHA224_DIGEST_LENGTH)
					case "sha256":
						algo = Int(kCCHmacAlgSHA256)
						size = Int(CC_SHA256_DIGEST_LENGTH)
					case "sha384":
						algo = Int(kCCHmacAlgSHA384)
						size = Int(CC_SHA384_DIGEST_LENGTH)
					case "sha512":
						algo = Int(kCCHmacAlgSHA512)
						size = Int(CC_SHA512_DIGEST_LENGTH)
					default:
						return nil
					}

				case "digits":
					switch item.value
					{
					case .some("6"):
						digits = 6
					case .some("8"):
						digits = 8
					default:
						return nil
					}

				default:
					continue
				}
			}
		}

		if secret.count == 0
		{
			return nil
		}
	}

	@objc required public init?(coder aDecoder: NSCoder)
	{
		account = aDecoder.decodeObject(forKey: "account") as! String
		secret = aDecoder.decodeObject(forKey: "secret") as! Data
		algo = aDecoder.decodeInteger(forKey: "algo")
		size = aDecoder.decodeInteger(forKey: "size")
		digits = aDecoder.decodeInteger(forKey: "digits")
		super.init()
	}

	@objc public func encode(with aCoder: NSCoder)
	{
		aCoder.encode(account, forKey: "account")
		aCoder.encode(secret, forKey: "secret")
		aCoder.encode(algo, forKey: "algo")
		aCoder.encode(size, forKey: "size")
		aCoder.encode(digits, forKey: "digits")
	}

	/// Produces url parameters that can be used to reconstruct a URL to import this token into another device.
	internal var urlParameters: [String: String]?
	{
		let algoName: String

		switch algo
		{
		case Int(kCCHmacAlgMD5):	algoName = "md5"
		case Int(kCCHmacAlgSHA1):	algoName = "sha1"
		case Int(kCCHmacAlgSHA224):	algoName = "sha224"
		case Int(kCCHmacAlgSHA256):	algoName = "sha256"
		case Int(kCCHmacAlgSHA384):	algoName = "sha384"
		case Int(kCCHmacAlgSHA512):	algoName = "sha512"
		default: return nil
		}

		return [
			"digits": "\(digits)",
			"algorithm": algoName,
			"secret": secret.base32EncodedString
		]
	}

	public func code(_ counter: Int64) -> String
	{
		// Network byte order
		var cnt = counter.bigEndian

		// Do the HMAC
		var buf = [UInt8](repeating: 0, count: size)
		CCHmac(UInt32(algo), (secret as NSData).bytes, secret.count, &cnt, MemoryLayout.size(ofValue: cnt), &buf)

		// Unparse UInt32
		let off = Int(buf[buf.count - 1]) & 0x0f;
		let msk = buf.withUnsafeMutableBufferPointer({ pointer in
			return pointer.baseAddress?.advanced(by: off).withMemoryRebound(to: UInt32.self, capacity: size/4)
			{
				$0[0].bigEndian & 0x7fffffff
			}
		})!

		// Create digits divisor
		var div: UInt32 = 1
		(0..<digits).forEach({ _ in div *= 10 })

		return String(format: String(format: "%%0%hhulu", digits), msk % div)
	}
}
