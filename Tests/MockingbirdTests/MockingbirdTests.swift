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

final class MockingbirdTests: XCTestCase {
    
    var mockingbird: Mockingbird<GitHub>!
    var delayedMockingbird: Mockingbird<GitHub>!
    var delayedResolutionMockingbird: Mockingbird<GitHub>!
    var middlewareItem: TestingMiddleware!
    let delay: TimeInterval = 0.5
    var asyncExpectation: XCTestExpectation!
    let beforeRequest: TimeInterval = 0.05
    let requestTime: TimeInterval = 0.1
    let beforeResponse: TimeInterval = 0.15
    let responseTime: TimeInterval = 0.2
    let afterResponse: TimeInterval = 0.3
    var customRequestLambdaMockingbird: Mockingbird<GitHub>!
    var executed = false
    var zenSuccessHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override func setUp() {
        mockingbird = Mockingbird<GitHub>(stubLambda: Mockingbird.immediatelyStub)
        middlewareItem = TestingMiddleware()
        delayedMockingbird = Mockingbird<GitHub>(stubLambda: Mockingbird.delayedStub(delay), middleware: [middlewareItem])
        let requestResolution: Mockingbird<GitHub>.RequestLambda = { request, done in
            delayExecution(self.requestTime) {
                do {
                    let urlRequest = try request.urlRequest()
                    done(.success(urlRequest))
                } catch MockingbirdError.requestMapping(let url) {
                    done(.failure(MockingbirdError.requestMapping(url)))
                } catch {
                    done(.failure(MockingbirdError.parameterEncoding(reason: .jsonEncodingFailed(error: error))))
                }
            }
        }
        delayedResolutionMockingbird = Mockingbird<GitHub>(requestLambda: requestResolution, stubLambda: Mockingbird.delayedStub(responseTime))
        let requestLambda: Mockingbird<GitHub>.RequestLambda = { request, done in
            self.executed = true
            do {
                let urlRequest = try request.urlRequest()
                done(.success(urlRequest))
            } catch MockingbirdError.requestMapping(let url) {
                done(.failure(MockingbirdError.requestMapping(url)))
            } catch {
                done(.failure(MockingbirdError.parameterEncoding(reason: .jsonEncodingFailed(error: error))))
            }
        }
        customRequestLambdaMockingbird = Mockingbird<GitHub>(requestLambda: requestLambda, stubLambda: Mockingbird.immediatelyStub)
        zenSuccessHandler = { request in
            let response = HTTPURLResponse(url: URL(string: url(GitHub.zen))!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = GitHub.zen.testData
            return (response, data)
        }
    }
    
    override func tearDown() { }
    
    func test_returns_sample_data_for_stubbed_zen_request() {
        var message: String?
        asyncExpectation = XCTestExpectation(description: "returns sample for stubbed zen request")
        mockingbird.request(.zen) { result in
            if case let .success(response) = result {
                message = String(data: response.data, encoding: .utf8)
                XCTAssertEqual(message, String(data: GitHub.zen.testData, encoding: .utf8))
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 1)
    }
    
    func test_returns_sample_data_for_stubbed_userprofile_request() {
        var message: String?
        asyncExpectation = XCTestExpectation(description: "returns sample for stubbed userprofile request")
        mockingbird.request(.userProfile("username")) { result in
            if case let .success(response) = result {
                message = String(data: response.data, encoding: .utf8)
                XCTAssertEqual(message, String(data: GitHub.userProfile("username").testData, encoding: .utf8))
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 1)
    }
    
    func test_returns_request_object_for_zen_stubbed_response() {
        asyncExpectation = XCTestExpectation(description: "returns request object when zen request is stubbed")
        mockingbird.request(.zen) { result in
            if case let .success(response) = result {
                XCTAssertNotNil(response.request)
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 1)
    }
    
    func test_returns_request_object_for_userprofile_stubbed_response() {
        asyncExpectation = XCTestExpectation(description: "returns request object when useProfile request is stubbed")
        mockingbird.request(.userProfile("username")) { result in
            if case let .success(response) = result {
                XCTAssertNotNil(response.request)
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 1)
    }
    
    func test_returns_equivalent_endpoint_instances_for_same_target() {
        let target: GitHub = .zen
        let request1 = mockingbird.request(target)
        let request2 = mockingbird.request(target)
        let urlRequest1 = try? request1.urlRequest()
        let urlRequest2 = try? request2.urlRequest()
        XCTAssertNotNil(urlRequest1)
        XCTAssertNotNil(urlRequest2)
        XCTAssertEqual(urlRequest1, urlRequest2)
    }
    
    func test_returns_a_cancellable_object_when_request_is_made() {
        let endpoint: GitHub = .userProfile("username")
        let requestOperation: RequestOperationType = mockingbird.request(endpoint) { _ in  }
        XCTAssertNotNil(requestOperation)
    }
    
    func test_mockingbird_accepts_a_custom_URLSessionConfiguration() {
        let configuration = URLSessionConfiguration.ephemeral
        let mockingbird = Mockingbird<GitHub>(sessionConfiguration: configuration)
        XCTAssertEqual(configuration, mockingbird.sessionConfiguration)
    }
    
    func test_when_stubbed_delayed_delays_execution() {
        let startDate = Date()
        var endDate: Date?
        let endpoint: GitHub = .zen
        asyncExpectation = XCTestExpectation(description: "when stubbed with delay the execution is delayed")
        delayedMockingbird.request(endpoint) { _ in
            endDate = Date()
            XCTAssertGreaterThanOrEqual(endDate!.timeIntervalSince(startDate), self.delay)
            self.asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 2)
    }
    
    func test_returns_error_when_request_is_cancelled() {
        let endpoint: GitHub = .userProfile("username")
        asyncExpectation = XCTestExpectation(description: "returns error when request is cancelled")
        let requestOperation = delayedMockingbird.request(endpoint) { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
                self.asyncExpectation.fulfill()
            }
        }
        requestOperation.cancel()
        wait(for: [asyncExpectation], timeout: 2)
    }
    
    func test_notifies_middleware_when_request_is_cancelled() {
        let endpoint: GitHub = .userProfile("username")
        asyncExpectation = XCTestExpectation(description: "notifies middleware when request is cancelled")
        let requestOperation = delayedMockingbird.request(endpoint) { _ in
            self.asyncExpectation.fulfill()
        }
        requestOperation.cancel()
        if let result = middlewareItem.result, case let .failure(error) = result {
            XCTAssertNotNil(error)
        }
        wait(for: [asyncExpectation], timeout: 2)
    }
    
    func test_it_prepares_request_using_middleware() {
        let endpoint: GitHub = .userProfile("username")
        asyncExpectation = XCTestExpectation(description: "prepares request using middleware")
        _ = delayedMockingbird.request(endpoint) { _ in
            XCTAssertTrue(self.middlewareItem.didPrepare)
            self.asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 2)
    }
    
    func test_it_returns_success_when_request_is_not_cancelled() {
        let endpoint: GitHub = .zen
        asyncExpectation = XCTestExpectation(description: "returns success when request is not cancelled")
        delayedMockingbird.request(endpoint) { result in
            if case let .failure(error) = result {
                XCTAssertNil(error)
            }
            self.asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 2)
    }
    
    func test_it_processes_response_with_middleware() {
        asyncExpectation = XCTestExpectation(description: "processes the response with middleware")
        let endpoint: GitHub = .userProfile("username")
        _ = delayedMockingbird.request(endpoint) { result in
            if case let .success(response) = result {
                XCTAssertEqual(response.statusCode, -1)
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 2)
    }
    
    func test_delayed_endpoint_resolution_returns_success_eventually() {
        asyncExpectation = XCTestExpectation(description: "delayed endpoint resolution returns success eventually")
        let endpoint: GitHub = .userProfile("username")
        delayedResolutionMockingbird.request(endpoint) { result in
            if case let .failure(error) = result {
                XCTAssertNil(error)
            }
            self.asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 2)
    }
    
    func test_delayed_endpoint_resolution_calls_completion_if_cancelled_immediately() {
        var calledCompletion = false
        let endpoint: GitHub = .userProfile("username")
        asyncExpectation = XCTestExpectation(description: "delayed endpoint resolution calls completion if cancelled immediately")
        let requestOperation = delayedResolutionMockingbird.request(endpoint) { result in
            calledCompletion = true
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
                XCTAssertTrue(calledCompletion)
            }
        }
        requestOperation.cancel()
        delayExecution(afterResponse) {
            self.asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 10)
    }
    
    func test_delayed_endpoint_resolution_calls_completion_if_cancelled_before_request_created() {
        asyncExpectation = XCTestExpectation(description: "delayed endpoint resolution calls completion if cancelled before request created")
        let endpoint: GitHub = .userProfile("username")
        let requestOperation = mockingbird.request(endpoint) { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
            }
        }
        delayExecution(beforeRequest) {
            requestOperation.cancel()
        }
        delayExecution(afterResponse) {
            self.asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 10)
    }
    
    func test_delayed_endpoint_resolution_receives_error_if_request_cancelled_before_response_comes_back() {
        asyncExpectation = XCTestExpectation(description: "delayed endpoint resolution receives error if request cancelled before response comes back")
        let endpoint: GitHub = .userProfile("username")
        let requestOperation = mockingbird.request(endpoint) { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
            }
            self.asyncExpectation.fulfill()
        }
        delayExecution(beforeResponse) {
            requestOperation.cancel()
        }
        wait(for: [asyncExpectation], timeout: 10)
    }
    
    func test_custom_request_lambda_executes_custom_lambda() {
        let endpoint: GitHub = .zen
        asyncExpectation = XCTestExpectation(description: "custom request lambda mockingbird executes custom lambda")
        customRequestLambdaMockingbird.request(endpoint) { _ in
            XCTAssertTrue(self.executed)
            self.asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 10)
    }
    
    func test_custom_endpoint_lambda_returns_sample_data() {
        asyncExpectation = XCTestExpectation(description: "custom endpoint lambda mockingbird returns sample data")
        let requestLambda: Mockingbird<GitHub>.EndpointToRequestLambda = { endpoint in
            let url = endpoint.baseURL.appendingPathComponent(endpoint.path).absoluteString
            return Request(url: url, sampleResponse: {.networkResponse(statusCode: 200, data: endpoint.testData)}, method: endpoint.method, requestType: endpoint.requestType, headers: endpoint.headers)
        }
        let mockingbird = Mockingbird<GitHub>(endpointToRequestLambda: requestLambda, stubLambda: Mockingbird.immediatelyStub)
        mockingbird.request(.zen) { result in
            if case .success(let response) = result {
                XCTAssertEqual(response.data, GitHub.zen.testData)
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 10)
    }
    
    func test_custom_endpoint_lambda_returns_identical_response() {
        asyncExpectation = XCTestExpectation(description: "custom endpoint lambda mockingbird returns identical response")
        let expectedResponse = HTTPURLResponse(url: URL(string: "http://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let requestLambda: Mockingbird<GitHub>.EndpointToRequestLambda = { endpoint in
            return Request(url: URL(endpoint: endpoint).absoluteString, sampleResponse: { .response(response: expectedResponse, data: endpoint.testData) }, method: endpoint.method, requestType: endpoint.requestType, headers: endpoint.headers)
        }
        let mockingbird = Mockingbird<GitHub>(endpointToRequestLambda: requestLambda, stubLambda: Mockingbird.immediatelyStub)
        mockingbird.request(.zen) { result in
            if case .success(let response) = result {
                XCTAssertEqual(response.response, expectedResponse)
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 10)
    }
    
    func test_custom_endpoint_lambda_returns_expected_network_error() {
        asyncExpectation = XCTestExpectation(description: "custom endpoint lambda mockingbird returns expected error")
        let expectedError = NSError(domain: "Internal iOS Error", code: -1234, userInfo: nil)
        let requestLambda: Mockingbird<GitHub>.EndpointToRequestLambda = { endpoint in
            let url = endpoint.baseURL.appendingPathComponent(endpoint.path).absoluteString
            return Request(url: url, sampleResponse: { .networkError(error: expectedError) }, method: endpoint.method, requestType: endpoint.requestType, headers: endpoint.headers)
        }
        let mockingbird = Mockingbird<GitHub>(endpointToRequestLambda: requestLambda, stubLambda: Mockingbird.immediatelyStub)
        var receivedError: MockingbirdError?
        mockingbird.request(.zen) { result in
            if case .failure(let error) = result {
                receivedError = error
                if case .some(MockingbirdError.network(let underlyingError as NSError, _)) = receivedError {
                    XCTAssertEqual(underlyingError, expectedError)
                } else {
                    XCTFail("Not the expected error")
                }
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 10)
    }
    
    func test_error_in_request_lambda_returns_failure() {
        asyncExpectation = XCTestExpectation(description: "error in request lambda returns failure for any request")
        let requestLambda: Mockingbird<GitHub>.RequestLambda = { request, done in
            let underyingError = NSError(domain: "", code: 123, userInfo: nil)
            done(.failure(.network(underyingError, nil)))
        }
        mockingbird = Mockingbird<GitHub>(requestLambda: requestLambda, stubLambda: Mockingbird.immediatelyStub)
        let endpoint: GitHub = .zen
        mockingbird.request(endpoint) { response in
            if case .failure(let error) = response {
                XCTAssertNotNil(error)
                self.asyncExpectation.fulfill()
            }
        }
        wait(for: [asyncExpectation], timeout: 10)
    }
    
    func test_mocked_errors_returns_failure() {
        mockingbird = Mockingbird(endpointToRequestLambda: failureRequestLambda, stubLambda: Mockingbird.immediatelyStub)
        asyncExpectation = XCTestExpectation(description: "mocked errors returns failure")
        let endpoint: GitHub = .zen
        mockingbird.request(endpoint) { result in
            if case .failure = result {
                self.asyncExpectation.fulfill()
            } else {
                XCTFail("Should have returned failure")
            }
        }
    }
    
    func test_mocked_errors_returns_stubbed_error_data() {
        mockingbird = Mockingbird(endpointToRequestLambda: failureRequestLambda, stubLambda: Mockingbird.immediatelyStub)
        asyncExpectation = XCTestExpectation(description: "mocked errors returns stubbed error data")
        var receivedError: MockingbirdError?
        let endpoint: GitHub = .userProfile("username")
        mockingbird.request(endpoint) { result in
            if case let .failure(error) = result {
                receivedError = error
            }
            switch receivedError {
            case .some(.network(let error, _)):
                XCTAssertEqual(error.localizedDescription, "I am error")
            default:
                XCTFail("Network error expected")
            }
            self.asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 10)
    }
    
    func test_with_inprogress_requests_returns_identical_response_for_inprogress_requests() {
        MockURLProtocol.requestHandler = zenSuccessHandler
        asyncExpectation = XCTestExpectation(description: "with inProgress requests should return identical responses")
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        mockingbird = Mockingbird<GitHub>(sessionConfiguration: configuration, trackInProgress: true)
        let endpoint: GitHub = .zen
        var receivedResponse: Response!
        XCTAssertEqual(mockingbird.inProgressRequests.keys.count, 0)
        mockingbird.request(endpoint) { result in
            if case let .success(response) = result {
                receivedResponse = response
            }
            XCTAssertEqual(self.mockingbird.inProgressRequests.keys.count, 1)
        }
        mockingbird.request(endpoint) { result in
            XCTAssertNotNil(receivedResponse)
            if case let .success(response) = result {
                XCTAssertEqual(receivedResponse, response)
            }
            XCTAssertEqual(self.mockingbird.inProgressRequests.keys.count, 1)
            self.asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 10)
    }
    
    func test_cancellable_request_calls_completion_and_returns_and_error_when_cancelled() {
        asyncExpectation = XCTestExpectation(description: "cancellable request finishes and returns with error when cancelled")
        mockingbird = Mockingbird<GitHub>(stubLambda: Mockingbird.delayedStub(0.5))
        let requestOperation = mockingbird.request(.zen, completion: { (result) in
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
                if case .network(let err, _) = error {
                    XCTAssertEqual((err as NSError).code, NSURLErrorCancelled)
                } else {
                    XCTFail("Error should be NSURLErrorCancelled")
                }
                self.asyncExpectation.fulfill()
            }
        })
        requestOperation.cancel()
        wait(for: [asyncExpectation], timeout: 10)
    }

    func test_stubbed_requests_with_validation_response_contains_invalid_status_code() {
        asyncExpectation = XCTestExpectation(description: "stubbed request with validation response contains invalid status code")
        let requestLambda = { (endpoint: GitHub) -> Request in
            return Request(url: URL(endpoint: endpoint).absoluteString, sampleResponse: { .networkResponse(statusCode: 400, data: endpoint.testData) }, method: endpoint.method, requestType: endpoint.requestType, headers: endpoint.headers
            )
        }
        mockingbird = Mockingbird<GitHub>(endpointToRequestLambda: requestLambda, stubLambda: Mockingbird.immediatelyStub)
        var receivedError: MockingbirdError?
        var receivedStatusCode: Int = 0
        var receivedResponse: Response?
        mockingbird.request(.zen) { result in
            switch result {
            case .success(let response):
                receivedResponse = response
            case .failure(let error):
                receivedError = error
                if case .invalidStatusCode(let response) = error {
                    receivedStatusCode = response.statusCode
                }
            }
            XCTAssertNil(receivedResponse)
            XCTAssertNotNil(receivedError)
            XCTAssertEqual(receivedStatusCode, 400)
            self.asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 10)
    }

    func test_stubbed_requests_with_validation_response_contains_valid_status_code() {
        asyncExpectation = XCTestExpectation(description: "stubbed request with validation response contains valid status code")
        let requestLambda = { (endpoint: GitHub) -> Request in
            return Request(url: URL(endpoint: endpoint).absoluteString, sampleResponse: { .networkResponse(statusCode: 200, data: endpoint.testData) }, method: endpoint.method, requestType: endpoint.requestType, headers: endpoint.headers
            )
        }
        mockingbird = Mockingbird<GitHub>(endpointToRequestLambda: requestLambda, stubLambda: Mockingbird.immediatelyStub)
        var receivedError: MockingbirdError?
        var receivedResponse: Response?
        mockingbird.request(.zen) { result in
            switch result {
            case .success(let response):
                receivedResponse = response
            case .failure(let error):
                receivedError = error
            }
            XCTAssertNotNil(receivedResponse)
            XCTAssertNil(receivedError)
            XCTAssertTrue(GitHub.zen.validation.statusCodes.contains(receivedResponse?.statusCode ?? 0))
            self.asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 10)
    }
}

extension MockingbirdTests {
    static var allTests = [
        ("test_returns_sample_data_for_stubbed_zen_request", test_returns_sample_data_for_stubbed_zen_request),
        ("test_returns_sample_data_for_stubbed_userprofile_request", test_returns_sample_data_for_stubbed_userprofile_request),
        ("test_returns_request_object_for_zen_stubbed_response", test_returns_request_object_for_zen_stubbed_response),
        ("test_returns_request_object_for_userprofile_stubbed_response", test_returns_request_object_for_userprofile_stubbed_response),
        ("test_returns_equivalent_endpoint_instances_for_same_target", test_returns_equivalent_endpoint_instances_for_same_target),
        ("test_returns_a_cancellable_object_when_request_is_made", test_returns_a_cancellable_object_when_request_is_made),
        ("test_mockingbird_accepts_a_custom_URLSessionConfiguration", test_mockingbird_accepts_a_custom_URLSessionConfiguration),
        ("test_when_stubbed_delayed_delays_execution", test_when_stubbed_delayed_delays_execution),
        ("test_returns_error_when_request_is_cancelled", test_returns_error_when_request_is_cancelled),
        ("test_notifies_middleware_when_request_is_cancelled", test_notifies_middleware_when_request_is_cancelled),
        ("test_it_prepares_request_using_middleware", test_it_prepares_request_using_middleware),
        ("test_it_returns_success_when_request_is_not_cancelled", test_it_returns_success_when_request_is_not_cancelled),
        ("test_it_processes_response_with_middleware", test_it_processes_response_with_middleware),
        ("test_delayed_endpoint_resolution_returns_success_eventually", test_delayed_endpoint_resolution_returns_success_eventually),
        ("test_delayed_endpoint_resolution_calls_completion_if_cancelled_immediately", test_delayed_endpoint_resolution_calls_completion_if_cancelled_immediately),
        ("test_delayed_endpoint_resolution_calls_completion_if_cancelled_before_request_created", test_delayed_endpoint_resolution_calls_completion_if_cancelled_before_request_created),
        ("test_delayed_endpoint_resolution_receives_error_if_request_cancelled_before_response_comes_back", test_delayed_endpoint_resolution_receives_error_if_request_cancelled_before_response_comes_back),
        ("test_custom_request_lambda_executes_custom_lambda", test_custom_request_lambda_executes_custom_lambda),
        ("test_custom_endpoint_lambda_returns_sample_data", test_custom_endpoint_lambda_returns_sample_data),
        ("test_custom_endpoint_lambda_returns_identical_response", test_custom_endpoint_lambda_returns_identical_response),
        ("test_custom_endpoint_lambda_returns_expected_network_error", test_custom_endpoint_lambda_returns_expected_network_error),
        ("test_error_in_request_lambda_returns_failure", test_error_in_request_lambda_returns_failure),
        ("test_mocked_errors_returns_failure", test_mocked_errors_returns_failure),
        ("test_mocked_errors_returns_stubbed_error_data", test_mocked_errors_returns_stubbed_error_data),
        ("test_with_inprogress_requests_returns_identical_response_for_inprogress_requests", test_with_inprogress_requests_returns_identical_response_for_inprogress_requests),
        ("test_cancellable_request_calls_completion_and_returns_and_error_when_cancelled", test_cancellable_request_calls_completion_and_returns_and_error_when_cancelled),
        ("test_stubbed_requests_with_validation_response_contains_invalid_status_code", test_stubbed_requests_with_validation_response_contains_invalid_status_code),
        ("test_stubbed_requests_with_validation_response_contains_valid_status_code", test_stubbed_requests_with_validation_response_contains_valid_status_code)
        ]
}
