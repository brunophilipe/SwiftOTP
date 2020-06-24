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

public final class Token : NSObject, KeychainStorable
{
	public static var supportsSecureCoding: Bool {
		return true
	}

	public static let store = KeychainStore<Token>()
	public let account: String

	public enum Kind: Int
	{
		case hotp = 0
		case totp = 1

		fileprivate var stringValue: String
		{
			switch self
			{
			case .hotp: return "hotp"
			case .totp: return "totp"
			}
		}
	}

	open class Code
	{
		fileprivate(set) open var value: String
		fileprivate(set) open var from: Date
		fileprivate(set) open var to: Date

		fileprivate init(_ value: String, _ from: Date, _ period: Int64)
		{
			self.value = value
			self.from = from
			self.to = from.addingTimeInterval(TimeInterval(period))
		}
	}

	fileprivate var issuerOrig: String = ""
	fileprivate var labelOrig: String = ""
	fileprivate var imageOrig: String?
	fileprivate var counter: Int64 = 0
	fileprivate var period: Int64 = 30

	fileprivate (set) public var kind: Kind = .hotp

	public var locked: Bool = false
	{
		didSet
		{
			if let otp = OTP.store.load(account), OTP.store.erase(otp), OTP.store.add(otp, locked: locked)
			{
				return
			}

			locked = !locked
		}
	}

	public var codes: [Code]
	{
		guard let otp = OTP.store.load(account) else
		{
			return []
		}

		let now = Date()

		switch kind
		{
		case .hotp:
			let code = Code(otp.code(counter), now, period)
			counter += 1
			return Token.store.save(self) ? [code] : []

		case .totp:
			func totp(_ otp: OTP, when: Date) -> Code
			{
				let c = Int64(when.timeIntervalSince1970) / period
				let i = Date(timeIntervalSince1970: TimeInterval(c * period))
				return Code(otp.code(c), i, period)
			}

			let next = now.addingTimeInterval(TimeInterval(period))
			return [totp(otp, when: now), totp(otp, when: next)]
		}
	}

	@objc public var issuer: String! = nil
	{
		didSet
		{
			if issuer == nil { issuer = issuerOrig }
		}
	}

	@objc public var label: String! = nil
	{
		didSet
		{
			if label == nil { label = labelOrig }
		}
	}

	@objc public var image: String? = nil
	{
		didSet
		{
			if image == nil { image = imageOrig }
		}
	}

	/// Returns the best code for near immediate use.
	///
	/// This routine will calculate the current code(s), and return the most appropriate one. If this is a HOTP token,
	/// returns the current code. If this is a TOTP code, returns the current code if it is still valid for the next
	/// 3 seconds. Otherwise returns the next code. The idea is to provide the user with a code that will be most
	/// likely be valid once they place the code in the clipboard and switch apps in order to paste it.
	public var bestCode: Code?
	{
		let codes = self.codes

		guard codes.count > 0 else
		{
			return nil
		}

		switch kind
		{
		case .hotp:
			return codes.first

		case .totp:
			let currentCode = codes.first!
			if currentCode.to.timeIntervalSinceNow > 3
			{
				return currentCode
			}
			else
			{
				return codes.last!
			}
		}
	}

	/// Reconstructs a URL that can be used to import this token into another device.
	public var asUrl: URL?
	{
		guard
			let escapedIssuer = issuer.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
			let escapedLabel = label.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
			var urlParameters = OTP.store.load(account)?.urlParameters
		else
		{
			return nil
		}

		// Create base url
		let urlString = "otpauth://\(kind.stringValue)/\(escapedIssuer):\(escapedLabel)"

		// Add non-secret parameters
		urlParameters["period"] = "\(period)"
		urlParameters["issuer"] = "\(escapedIssuer)"

		// Build the url object
		return URL(string: urlString + "?" + urlParameters.map({"\($0)=\($1)"}).joined(separator: "&"))
	}

	public init?(otp: OTP, urlc: URLComponents, load: Bool = false)
	{
		self.account = otp.account
		super.init()

		if urlc.scheme != "otpauth" || urlc.host == nil
		{
			return nil
		}

		// Get kind
		switch urlc.host!.lowercased()
		{
		case "totp":
			kind = .totp

		case "hotp":
			kind = .hotp

		default:
			return nil
		}

		// Normalize path
		var path = urlc.path
		while path.hasPrefix("/")
		{
			path = String(path[path.index(path.startIndex, offsetBy: 1)...])
		}

		if path == ""
		{
			return nil
		}

		// Get issuer and label
		let comps = path.components(separatedBy: ":")
		issuer = comps[0]
		label = comps.count > 1 ? comps[1] : ""

		let query = urlc.queryItems

		guard query != nil else
		{
			return nil
		}

		for item: URLQueryItem in query!
		{
			guard item.value != nil else
			{
				continue
			}

			switch item.name.lowercased()
			{
			case "period":
				if let tmp = Int64(item.value!)
				{
					if tmp < 5
					{
						return nil
					}

					period = tmp
				}

			case "counter":
				if let tmp = Int64(item.value!)
				{
					if tmp < 0
					{
						return nil
					}

					counter = tmp
				}

			case "lock":
				switch item.value!.lowercased()
				{
				case "": fallthrough
				case "0": fallthrough
				case "off": fallthrough
				case "false":
					locked = false

				default:
					locked = Token.store.lockingSupported
				}

			case "image":
				image = item.value!
				if !load { image = item.value! }

			case "issuerorig":
				if !load { issuerOrig = item.value! }

			case "nameorig":
				if !load { labelOrig = item.value! }

			case "imageorig":
				if !load { imageOrig = item.value! }

			default:
				continue
			}
		}

		if load
		{
			// This works around a bug where we stored a URL to the default image,
			// but this changed with the app id.
			if image != nil && image!.hasPrefix("file:") && image!.hasSuffix("/FreeOTP.app/default.png")
			{
				image = nil
			}
			if imageOrig != nil && imageOrig!.hasPrefix("file:") && imageOrig!.hasSuffix("/FreeOTP.app/default.png")
			{
				imageOrig = nil
			}
		}
		else
		{
			imageOrig = image
			issuerOrig = issuer
			labelOrig = label
		}
	}

	@objc required public init?(coder aDecoder: NSCoder)
	{
		if let account = aDecoder.decodeString(forKey: "account"),
		   let issuer = aDecoder.decodeString(forKey: "issuer"),
		   let issuerOrig = aDecoder.decodeString(forKey: "issuerOrig"),
		   let kind = Kind(rawValue: aDecoder.decodeInteger(forKey: "kind")),
		   let label = aDecoder.decodeString(forKey: "label"),
		   let labelOrig = aDecoder.decodeString(forKey: "labelOrig") {
			self.account = account
			self.issuer = issuer
			self.issuerOrig = issuerOrig
			self.kind = kind
			self.label = label
			self.labelOrig = labelOrig
		} else {
			return nil
		}

		image = aDecoder.decodeString(forKey: "image")
		imageOrig = aDecoder.decodeString(forKey: "imageOrig")
		locked = aDecoder.decodeBool(forKey: "locked")
		counter = aDecoder.decodeInt64(forKey: "counter")
		period = aDecoder.decodeInt64(forKey: "period")

		super.init()
	}

	@objc public func encode(with aCoder: NSCoder)
	{
		aCoder.encode(locked, forKey: "locked")
		aCoder.encode(account, forKey: "account")
		aCoder.encode(counter, forKey: "counter")
		aCoder.encode(image, forKey: "image")
		aCoder.encode(imageOrig, forKey: "imageOrig")
		aCoder.encode(issuer, forKey: "issuer")
		aCoder.encode(issuerOrig, forKey: "issuerOrig")
		aCoder.encode(kind.rawValue, forKey: "kind")
		aCoder.encode(label, forKey: "label")
		aCoder.encode(labelOrig, forKey: "labelOrig")
		aCoder.encode(period, forKey: "period")
	}
}
