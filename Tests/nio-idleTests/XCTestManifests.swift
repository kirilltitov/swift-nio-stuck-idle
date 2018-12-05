import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(nio_idleTests.allTests),
    ]
}
#endif