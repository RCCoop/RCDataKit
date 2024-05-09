//
//  KeyPathTests.swift
//  
//
//  Created by Ryan Linn on 5/8/24.
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
