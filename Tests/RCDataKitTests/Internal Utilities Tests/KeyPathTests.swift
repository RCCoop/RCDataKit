//
//  KeyPathTests.swift
//  

import XCTest
@testable import RCDataKit

final class KeyPathTests: XCTestCase {
    func testKeyPathStrings() {
        XCTAssertEqual((\Person.firstName).stringRepresentation, "firstName")
        XCTAssertEqual((\School.name).stringRepresentation, "name")
    }
    
    func testFailingKeyPaths() {
        XCTAssertFatalError {
            _ = (\Person.fullName).stringRepresentation
        }
    }
}
