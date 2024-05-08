//
//  XCTestCase+FatalError.swift
//
//  Implementation based on https://stackoverflow.com/a/68496755/1275947

import Foundation
import XCTest
@testable import RCDataKit

extension XCTestCase {
    func XCTAssertFatalError(expectedMessage: String? = nil, testcase: @escaping () -> Void) {

        // Set up expectation
        let expectation = self.expectation(description: "expectingFatalError")
        var assertionMessage: String? = nil

        // override fatalError. Terminate thread when fatalError is called
        FatalErrorUtility.replaceFatalError { message, _, _ in
            DispatchQueue.main.async {
                assertionMessage = message
                expectation.fulfill()
            }
            // Terminate current thread
            Thread.exit()
            // Since current thread is terminated, this new fatalError won't be executed:
            fatalError("This should never be called")
        }

        // Perform test case on separate thead so that it can be terminated
        Thread(block: testcase).start()

        waitForExpectations(timeout: 0.1) { _ in
            // assert if a specific message is expected
            if expectedMessage != nil {
                XCTAssertEqual(assertionMessage, expectedMessage)
            }
            
            // restore original fatal error
            FatalErrorUtility.restoreFatalError()
        }
    }
    
    func XCTAssertNoFatalError(testcase: @escaping () -> Void) {
        // Set up expectation to succeed if its never fulfilled
        let expectation = self.expectation(description: "expectingFatalError")
        expectation.isInverted = true
        
        // override fatalError. Terminate thread when fatalError is called
        FatalErrorUtility.replaceFatalError { message, _, _ in
            DispatchQueue.main.async {
                expectation.fulfill()
            }
            // Terminate current thread
            Thread.exit()
            // Since current thread is terminated, this new fatalError won't be executed:
            fatalError("This should never be called")
        }

        // Perform test case on separate thead so that it can be terminated
        Thread(block: testcase).start()

        waitForExpectations(timeout: 0.1) { _ in
            // restore original fatal error
            FatalErrorUtility.restoreFatalError()
        }
    }
}

// MARK: - Test of Test

class FailureTest: XCTestCase {
    func testFatalError() {
        XCTAssertFatalError {
            fatalError("This gotta fail")
        }
    }
    
    func testLackOfFatalError() {
        XCTAssertNoFatalError {
            print("No fatal error")
        }
    }
}
