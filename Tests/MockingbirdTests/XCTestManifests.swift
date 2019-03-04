import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MockingbirdTests.allTests),
        testCase(MockingbirdErrorTests.allTests),
        testCase(MockingbirdErrorTests.allTests),
        testCase(MockingbirdIntegrationTests.allTests),
        testCase(RequestTests.allTests),
        testCase(Single_MockingbirdTests.allTests),
        testCase(Observable_MockingbirdTests.allTests),
        testCase(Rx_MockingbirdTests.allTests)
    ]
}
#endif
