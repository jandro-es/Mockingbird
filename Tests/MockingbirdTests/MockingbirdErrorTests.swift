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
@testable import Mockingbird

final class MockingbirdErrorTests: XCTestCase {

    var response: Response!

    override func setUp() {
        response = Response(statusCode: 200, data: Data(), urlRequest: nil, response: nil)
    }

    override func tearDown() { }

    func test_jsonmapping_error_should_have_response() {
        let error = MockingbirdError.jsonMapping(response)
        XCTAssertEqual(error.response, response)
    }

    func test_stringmapping_error_should_have_response() {
        let error = MockingbirdError.stringMapping(response)
        XCTAssertEqual(error.response, response)
    }

    func test_invalidstatuscode_error_should_have_response() {
        let error = MockingbirdError.invalidStatusCode(response)
        XCTAssertEqual(error.response, response)
    }

    func test_network_error_should_not_have_response() {
        let someError = NSError(domain: "Domain", code: 200, userInfo: ["data": "some data"])
        let error = MockingbirdError.network(someError, nil)
        XCTAssertNil(error.response)
    }

    func test_mapping_result_empty_data_throws_error() {
        do {
            _ = try response.mapJSON()
            XCTFail("Should fail")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func test_returns_valid_for_mapjson_with_flag() {
        do {
            let value = try response.mapJSON(failsOnEmptyData: false)
            XCTAssertNotNil(value)
        } catch {
            XCTFail("Should not failt")
        }
    }

    func test_should_return_network_error_even_having_response_and_data() {
        let nsError = NSError(domain: "", code: 0, userInfo: nil)
        let urlRequest = NSURLRequest() as URLRequest
        let response = HTTPURLResponse()
        let data = Data()
        let result = Mockingbird<GitHub>.mapResponseToResult(response, urlRequest: urlRequest, validStatusCodes: [200], data: data, error: nsError)
        switch result {
        case let .failure(error):
            switch error {
            case let .network(error, _):
                XCTAssertEqual(error as NSError, nsError)
            default:
                XCTFail("expected to get NSError error")
            }
        case .success:
            XCTFail("should fail as there is an error")
        }
    }
}

extension MockingbirdErrorTests {
    static var allTests = [
        ("test_jsonmapping_error_should_have_response", test_jsonmapping_error_should_have_response),
        ("test_stringmapping_error_should_have_response", test_stringmapping_error_should_have_response),
        ("test_invalidstatuscode_error_should_have_response", test_invalidstatuscode_error_should_have_response),
        ("test_network_error_should_not_have_response", test_network_error_should_not_have_response),
        ("test_mapping_result_empty_data_throws_error", test_mapping_result_empty_data_throws_error),
        ("test_returns_valid_for_mapjson_with_flag", test_returns_valid_for_mapjson_with_flag),
        ("test_should_return_network_error_even_having_response_and_data", test_should_return_network_error_even_having_response_and_data)
    ]
}
