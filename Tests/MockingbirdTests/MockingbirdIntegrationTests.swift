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

final class MockingbirdIntegrationTests: XCTestCase {

    let userMessage = String(data: GitHub.userProfile("username").testData, encoding: .utf8)
    let zenMessage = String(data: GitHub.zen.testData, encoding: .utf8)
    var mockingbird: Mockingbird<GitHub>!
    var configuration: URLSessionConfiguration!
    var asyncExpectation: XCTestExpectation!
    var zenSuccessHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    var userProfileSuccessHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    var userProfile400Handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    var downloadFileHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    var filePath: URL!

    override func setUp() {
        configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        mockingbird = Mockingbird<GitHub>(sessionConfiguration: configuration)
        zenSuccessHandler = { request in
            let response = HTTPURLResponse(url: URL(string: url(GitHub.zen))!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = GitHub.zen.testData
            return (response, data)
        }
        userProfileSuccessHandler = { request in
            let response = HTTPURLResponse(url: URL(string: url(GitHub.userProfile("username")))!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = GitHub.userProfile("username").testData
            return (response, data)
        }
        userProfile400Handler = { request in
            let response = HTTPURLResponse(url: URL(string: url(GitHub.userProfile("invalid")))!, statusCode: 400, httpVersion: nil, headerFields: nil)!
            let data = GitHub.userProfile("invalid").testData
            return (response, data)
        }
        downloadFileHandler = { request in
            let response = HTTPURLResponse(url: URL(string: url(GitHub.downloadFile("logo.png")))!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = GitHub.downloadFile("logo.png").testData
            return (response, data)
        }
        let directories = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        filePath = directories.first!.appendingPathComponent("logo.png")
        try? FileManager.default.removeItem(at: filePath)
    }

    override func tearDown() { }

    func test_zen_request_returns_real_data() {
        MockURLProtocol.requestHandler = zenSuccessHandler
        asyncExpectation = XCTestExpectation(description: "returns real data for zen request")
        mockingbird.request(.zen) { result in
            if case let .success(response) = result {
                XCTAssertEqual(String(data: response.data, encoding: .utf8), self.zenMessage)
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 1)
    }

    func test_userprofile_returns_real_data() {
        MockURLProtocol.requestHandler = userProfileSuccessHandler
        asyncExpectation = XCTestExpectation(description: "returns real data for user profile request")
        mockingbird.request(.userProfile("username")) { result in
            if case let .success(response) = result {
                XCTAssertEqual(String(data: response.data, encoding: .utf8), self.userMessage)
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 1)
    }

    func test_returns_real_response_when_validation_fails() {
        MockURLProtocol.requestHandler = userProfile400Handler
        asyncExpectation = XCTestExpectation(description: "returns real response when validation fails")
        mockingbird.request(.userProfile("invalid")) { result in
            if case let .failure(error) = result {
                let response = error.response
                XCTAssertNotNil(response)
                XCTAssertEqual(response?.statusCode, 400)
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 1)
    }

    func test_uses_background_queue_when_specified_in_request() {
        MockURLProtocol.requestHandler = zenSuccessHandler
        let bgQueue = DispatchQueue(label: "background_queue", attributes: .concurrent)
        asyncExpectation = XCTestExpectation(description: "uses background queue when specified in request")
        mockingbird.request(.zen, queue: bgQueue) { result in
            if case let .success(response) = result {
                XCTAssertNotNil(response)
                XCTAssertFalse(Thread.isMainThread)
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 1)
    }

    func test_uses_main_queue_by_default() {
        MockURLProtocol.requestHandler = zenSuccessHandler
        asyncExpectation = XCTestExpectation(description: "uses main queue by default")
        mockingbird.request(.zen) { result in
            if case let .success(response) = result {
                XCTAssertNotNil(response)
                XCTAssertTrue(Thread.isMainThread)
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 1)
    }

    func test_uses_queue_defined_in_instance() {
        let bgQueue = DispatchQueue(label: "background_queue", attributes: .concurrent)
        mockingbird = Mockingbird<GitHub>(queue: bgQueue, sessionConfiguration: configuration)
        MockURLProtocol.requestHandler = zenSuccessHandler
        asyncExpectation = XCTestExpectation(description: "uses queue defined in the main instance")
        mockingbird.request(.zen) { result in
            if case let .success(response) = result {
                XCTAssertNotNil(response)
                XCTAssertFalse(Thread.isMainThread)
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 1)
    }

    func test_network_activity_middleware_notifies_at_beginning() {
        MockURLProtocol.requestHandler = zenSuccessHandler
        var called = false
        var endpointCalled: GitHub?
        let middleware = NetworkActivityMiddleware { status, endpoint in
            if status == .began {
                called = true
                endpointCalled = endpoint as? GitHub
            }
        }
        let mockingbird = Mockingbird<GitHub>(sessionConfiguration: configuration, middleware: [middleware])
        let target: GitHub = .zen
        asyncExpectation = XCTestExpectation(description: "Network Activity middleware is called at the beginning of request")
        mockingbird.request(target) { _ in
            XCTAssertTrue(called)
            XCTAssertEqual(endpointCalled, target)
            self.asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 1)
    }

    func test_network_activity_middleware_notifies_at_end() {
        MockURLProtocol.requestHandler = zenSuccessHandler
        var called = false
        var endpointCalled: GitHub?
        let middleware = NetworkActivityMiddleware { status, endpoint in
            if status == .ended {
                called = true
                endpointCalled = endpoint as? GitHub
            }
        }
        let mockingbird = Mockingbird<GitHub>(sessionConfiguration: configuration, middleware: [middleware])
        let target: GitHub = .zen
        asyncExpectation = XCTestExpectation(description: "Network Activity middleware is called at the end of request")
        mockingbird.request(target) { _ in
            XCTAssertTrue(called)
            XCTAssertEqual(endpointCalled, target)
            self.asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 1)
    }

    func test_access_token_middleware_bearer() {
        MockURLProtocol.requestHandler = zenSuccessHandler
        let token = UUID().uuidString
        let expectedAuthHeader = ["Authorization": "Bearer \(token)"]
        let middleware = AccessTokenMiddleware {
            return token
        }
        mockingbird = Mockingbird<GitHub>(sessionConfiguration: configuration, middleware: [middleware])
        asyncExpectation = XCTestExpectation(description: "Access Token Bearer adds the proper header before request")
        mockingbird.request(.zen) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                XCTAssertNotNil(response.request)
                XCTAssertEqual(response.request?.allHTTPHeaderFields, expectedAuthHeader)
                self.asyncExpectation.fulfill()
            case .failure:
                XCTFail("It should succeed")
            }
        }
        wait(for: [asyncExpectation], timeout: 1)
    }

    func test_access_token_middleware_basic() {
        MockURLProtocol.requestHandler = zenSuccessHandler
        let token = UUID().uuidString
        let expectedAuthHeader = ["Authorization": "Basic \(token)"]
        let middleware = AccessTokenMiddleware {
            return token
        }
        let mockingbird = Mockingbird<GitHubBasic>(sessionConfiguration: configuration, middleware: [middleware])
        asyncExpectation = XCTestExpectation(description: "Access Token Basic adds the proper header before request")
        mockingbird.request(.zen) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                XCTAssertNotNil(response.request)
                XCTAssertEqual(response.request?.allHTTPHeaderFields, expectedAuthHeader)
                self.asyncExpectation.fulfill()
            case .failure:
                XCTFail("It should succeed")
            }
        }
        wait(for: [asyncExpectation], timeout: 1)
    }

    func test_access_token_middleware_custom() {
        MockURLProtocol.requestHandler = zenSuccessHandler
        let token = UUID().uuidString
        let expectedAuthHeader = ["Authorization": "FakeAuth \(token)"]
        let middleware = AccessTokenMiddleware {
            return token
        }
        let mockingbird = Mockingbird<GitHubCustom>(sessionConfiguration: configuration, middleware: [middleware])
        asyncExpectation = XCTestExpectation(description: "Access Token Custom adds the proper header before request")
        mockingbird.request(.zen) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                XCTAssertNotNil(response.request)
                XCTAssertEqual(response.request?.allHTTPHeaderFields, expectedAuthHeader)
                self.asyncExpectation.fulfill()
            case .failure:
                XCTFail("It should succeed")
            }
        }
        wait(for: [asyncExpectation], timeout: 1)
    }

    func test_access_token_middleware_none() {
        MockURLProtocol.requestHandler = zenSuccessHandler
        let token = UUID().uuidString
        let expectedAuthHeader: [String: String] = [:]
        let middleware = AccessTokenMiddleware {
            return token
        }
        let mockingbird = Mockingbird<GitHubNone>(sessionConfiguration: configuration, middleware: [middleware])
        asyncExpectation = XCTestExpectation(description: "Access Token None does not add anyheader before request")
        mockingbird.request(.zen) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                XCTAssertNotNil(response.request)
                XCTAssertEqual(response.request?.allHTTPHeaderFields, expectedAuthHeader)
                self.asyncExpectation.fulfill()
            case .failure:
                XCTFail("It should succeed")
            }
        }
        wait(for: [asyncExpectation], timeout: 1)
    }

    func test_download_file() {
        MockURLProtocol.requestHandler = downloadFileHandler
        asyncExpectation = XCTestExpectation(description: "logo.png is copied correctly")
        let endpoint = GitHub.downloadFile("logo.png")
        mockingbird.request(endpoint) { result in
            switch result {
            case .success:
                let data = NSData(contentsOf: self.filePath)
                XCTAssertNotNil(data)
                XCTAssertEqual(data?.length, 5000)
                self.asyncExpectation.fulfill()
            case .failure:
                XCTFail("No failure expected")
            }
        }
        wait(for: [asyncExpectation], timeout: 10)
    }
}

extension MockingbirdIntegrationTests {
    static var allTests = [
        ("test_zen_request_returns_real_data", test_zen_request_returns_real_data),
        ("test_userprofile_returns_real_data", test_userprofile_returns_real_data),
        ("test_returns_real_response_when_validation_fails", test_returns_real_response_when_validation_fails),
        ("test_uses_background_queue_when_specified_in_request", test_uses_background_queue_when_specified_in_request),
        ("test_uses_main_queue_by_default", test_uses_main_queue_by_default),
        ("test_uses_queue_defined_in_instance", test_uses_queue_defined_in_instance),
        ("test_network_activity_middleware_notifies_at_beginning", test_network_activity_middleware_notifies_at_beginning),
        ("test_network_activity_middleware_notifies_at_end", test_network_activity_middleware_notifies_at_end),
        ("test_access_token_middleware_bearer", test_access_token_middleware_bearer),
        ("test_access_token_middleware_basic", test_access_token_middleware_basic),
        ("test_access_token_middleware_custom", test_access_token_middleware_custom),
        ("test_access_token_middleware_none", test_access_token_middleware_none),
        ("test_download_file", test_download_file)
    ]
}
