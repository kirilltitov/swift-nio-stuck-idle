import XCTest

import nio_idleTests

var tests = [XCTestCaseEntry]()
tests += nio_idleTests.allTests()
XCTMain(tests)