import XCTest

import SuitTests

var tests = [XCTestCaseEntry]()
tests += SuitTests.__allTests()

XCTMain(tests)
