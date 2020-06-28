//
//  OTPKitTests.swift
//  OTPKitTests
//
//  Created by Bruno Philipe on 7/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import XCTest
import OTPKit

class OTPKitTests: XCTestCase {

	
	func testStringClustering() {
		XCTAssertEqual("".dividedIntoClusters(), "")
		XCTAssertEqual("1".dividedIntoClusters(), "1")
		XCTAssertEqual("12".dividedIntoClusters(), "12")
		XCTAssertEqual("123".dividedIntoClusters(), "123")
		XCTAssertEqual("1234".dividedIntoClusters(), "12 34")
		XCTAssertEqual("12345".dividedIntoClusters(), "12345")
		XCTAssertEqual("123456".dividedIntoClusters(), "123 456")
		XCTAssertEqual("1234567".dividedIntoClusters(), "1234567")
		XCTAssertEqual("12345678".dividedIntoClusters(), "1234 5678")
		XCTAssertEqual("123456789".dividedIntoClusters(), "123 456 789")
	}

	func testStringClusteringWithExplicitLength() {
		XCTAssertEqual("".dividedIntoClusters(of: 1), "")
		XCTAssertEqual("1".dividedIntoClusters(of: 1), "1")
		XCTAssertEqual("12".dividedIntoClusters(of: 1), "1 2")
		XCTAssertEqual("123".dividedIntoClusters(of: 1), "1 2 3")
		XCTAssertEqual("1234".dividedIntoClusters(of: 1), "1 2 3 4")
		XCTAssertEqual("12345".dividedIntoClusters(of: 1), "1 2 3 4 5")
		XCTAssertEqual("123456".dividedIntoClusters(of: 1), "1 2 3 4 5 6")
		XCTAssertEqual("1234567".dividedIntoClusters(of: 1), "1 2 3 4 5 6 7")
		XCTAssertEqual("12345678".dividedIntoClusters(of: 1), "1 2 3 4 5 6 7 8")
		XCTAssertEqual("123456789".dividedIntoClusters(of: 1), "1 2 3 4 5 6 7 8 9")
	}

	func testStringClusteringForSpeech() {
		XCTAssertEqual("".dividedIntoClusters(forSpeech: true), "")
		XCTAssertEqual("1".dividedIntoClusters(forSpeech: true), "1")
		XCTAssertEqual("12".dividedIntoClusters(forSpeech: true), "1 2")
		XCTAssertEqual("123".dividedIntoClusters(forSpeech: true), "1 2 3")
		XCTAssertEqual("1234".dividedIntoClusters(forSpeech: true), "1 2, 3 4")
		XCTAssertEqual("12345".dividedIntoClusters(forSpeech: true), "1 2 3 4 5")
		XCTAssertEqual("123456".dividedIntoClusters(forSpeech: true), "1 2 3, 4 5 6")
		XCTAssertEqual("1234567".dividedIntoClusters(forSpeech: true), "1 2 3 4 5 6 7")
		XCTAssertEqual("12345678".dividedIntoClusters(forSpeech: true), "1 2 3 4, 5 6 7 8")
		XCTAssertEqual("123456789".dividedIntoClusters(forSpeech: true), "1 2 3, 4 5 6, 7 8 9")
	}

}
