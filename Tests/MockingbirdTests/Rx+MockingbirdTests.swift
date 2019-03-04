// The MIT License
//
// Copyright (c) 2018-2019 Alejandro Barros Cuetos. jandro@filtercode.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import XCTest
import RxSwift
@testable import Mockingbird
@testable import RxMockingbird

final class Rx_MockingbirdTests: XCTestCase {

    var mockingbird: Mockingbird<GitHub>!
    var failMockingbird: Mockingbird<GitHub>!
    var zenSuccessHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    var asyncExpectation: XCTestExpectation!

    override func setUp() {
        mockingbird = Mockingbird<GitHub>(stubLambda: Mockingbird.immediatelyStub)
        failMockingbird = Mockingbird<GitHub>(endpointToRequestLambda: failureRequestLambda, stubLambda: Mockingbird.immediatelyStub)
        zenSuccessHandler = { request in
            let response = HTTPURLResponse(url: URL(string: url(GitHub.zen))!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = GitHub.zen.testData
            return (response, data)
        }
    }

    override func tearDown() { }

    func test_response_is_emited() {
        _ = mockingbird.rx.request(.zen).subscribe { event in
            switch event {
            case .success:
                break
            case .error:
                XCTFail("Expected to succeed")
            }
        }
    }

    func test_emits_stubbed_data() {
        let target: GitHub = .zen
        _ = mockingbird.rx.request(target).subscribe { event in
            switch event {
            case .success(let response):
                XCTAssertEqual(response.data, target.testData)
            case .error:
                XCTFail("Expected to succeed")
            }
        }
    }

    func test_maps_json_data() {
        let endpoint: GitHub = .userProfile("username")
        _ = mockingbird.rx.request(endpoint).asObservable().mapJSON().subscribe(onNext: { response in
            XCTAssertNotNil(response as? [String: Any])
        })
    }

    func test_emits_correct_error() {
        var receivedError: MockingbirdError?
        _ = failMockingbird.rx.request(.zen).subscribe { event in
            switch event {
            case .success:
                XCTFail("Expecting an error")
            case .error(let error):
                receivedError = error as? MockingbirdError
                switch receivedError {
                case .some(.network(let error, _)):
                    XCTAssertEqual(error.localizedDescription, "I am error")
                default:
                    XCTFail("Not the expected error")
                }
            }
        }
    }

    func test_rx_returns_identical_responses_for_inprogress() {
        MockURLProtocol.requestHandler = zenSuccessHandler
        asyncExpectation = XCTestExpectation(description: "with inProgress requests should return identical responses")
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        mockingbird = Mockingbird<GitHub>(sessionConfiguration: configuration, trackInProgress: true)
        let endpoint: GitHub = .zen
        let observable1 = mockingbird.rx.request(endpoint)
        let observable2 = mockingbird.rx.request(endpoint)
        XCTAssertEqual(mockingbird.inProgressRequests.count, 0)
        var receivedResponse: Response!
        _ = observable1.subscribe { event in
            switch event {
            case .success(let response):
                XCTAssertNotNil(response)
                receivedResponse = response
                XCTAssertEqual(self.mockingbird.inProgressRequests.count, 1)
            case .error:
                XCTFail("Expecting to suceed")
            }
        }
        _ = observable2.subscribe { event in
            switch event {
            case .success(let response):
                XCTAssertNotNil(response)
                XCTAssertEqual(response, receivedResponse)
                XCTAssertEqual(self.mockingbird.inProgressRequests.count, 1)
                self.asyncExpectation.fulfill()
            case .error:
                XCTFail("Expecting to suceed")
            }
        }
        wait(for: [asyncExpectation], timeout: 10)
    }
}

extension Rx_MockingbirdTests {
    static var allTests = [
        ("test_response_is_emited", test_response_is_emited),
        ("test_emits_stubbed_data", test_emits_stubbed_data),
        ("test_maps_json_data", test_maps_json_data),
        ("test_emits_correct_error", test_emits_correct_error),
        ("test_rx_returns_identical_responses_for_inprogress", test_rx_returns_identical_responses_for_inprogress)
    ]
}
