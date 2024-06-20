//
//  KeyPathTests.swift
//  

import XCTest
@testable import RCDataKit

final class KeyPathTests: XCTestCase {
    func testKeyPathStrings() {
        XCTAssertEqual((\Person.firstName).stringRepresentation, "firstName")
        XCTAssertEqual((\Course.title).stringRepresentation, "title")
    }
    
    func testFailingKeyPaths() {
        XCTAssertFatalError {
            _ = (\Person.fullName).stringRepresentation
        }
    }
}
