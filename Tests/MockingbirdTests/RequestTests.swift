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

final class RequestTests: XCTestCase {
    
    var request: Request!
    var simpleGitHubRequest: Request {
        let endpoint: GitHub = .zen
        let headerFields = ["Title": "Github API"]
        return Request(url: url(endpoint), sampleResponse: { .networkResponse(statusCode: 200, data: endpoint.testData) }, method: .get, requestType: .plain, headers: headerFields)
    }
    
    override func setUp() {
        request = simpleGitHubRequest
    }
    
    override func tearDown() { }
    
    func test_adding_new_header_creates_new_endpoint() {
        let agent = "MacOS"
        let newRequest = request.requestByAdding(headers: ["User-Agent": agent])
        let newRequestAgent = newRequest.headers?["User-Agent"]
        XCTAssertEqual(newRequestAgent, agent)
        XCTAssertEqual(newRequest.url, request.url)
        XCTAssertEqual(newRequest.method, request.method)
        XCTAssertNotEqual(newRequest, request)
    }
    
    func test_returns_nil_urlrequest_for_invalid_url() {
        let badRequest = Request(url: "invalid URL", sampleResponse: { .networkResponse(statusCode: 200, data: Data()) }, method: .get, requestType: .plain, headers: nil)
        let urlRequest = try? badRequest.urlRequest()
        XCTAssertNil(urlRequest)
    }
    
    func test_request_type_plain_endpoint_with_request_not_changed() {
        let newRequest = request.requestByReplacing(requestType: .plain)
        let urlRequest = try! newRequest.urlRequest()
        XCTAssertNil(urlRequest.httpBody)
        XCTAssertEqual(urlRequest.url?.absoluteString, request.url)
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, request.headers)
        XCTAssertEqual(urlRequest.httpMethod, request.method.rawValue)
    }
    
    func test_request_type_parameters_endpoint_encoded_parameters() {
        let parameters = ["Baddie": "Darth Vader"]
        let encoding = JSONEncoding.default
        let request = simpleGitHubRequest.requestByReplacing(requestType: .parameters(parameters: parameters, encoding: encoding))
        let urlRequest = try! request.urlRequest()
        let newRequest = request.requestByReplacing(requestType: .plain)
        let newUrlRequest = try! newRequest.urlRequest()
        let newEncodedRequest = try? encoding.encode(newUrlRequest, with: parameters)
        XCTAssertEqual(urlRequest.httpBody, newEncodedRequest?.httpBody)
        XCTAssertEqual(urlRequest.url?.absoluteString, newEncodedRequest?.url?.absoluteString)
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, newEncodedRequest?.allHTTPHeaderFields)
        XCTAssertEqual(urlRequest.httpMethod, newEncodedRequest?.httpMethod)
    }
    
    func test_request_type_data_updated_httpbody_but_not_other_properties() {
        var data: Data!
        var urlRequest: URLRequest!
        data = "test data".data(using: .utf8)
        request = request.requestByReplacing(requestType: .data(data))
        urlRequest = try! request.urlRequest()
        XCTAssertEqual(urlRequest.httpBody, data)
        XCTAssertEqual(urlRequest.url?.absoluteString, request.url)
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, request.headers)
        XCTAssertEqual(urlRequest.httpMethod, request.method.rawValue)
    }
    
    func test_request_type_jsonencodable_updates_body() {
        var issue: Issue!
        var urlRequest: URLRequest!
        issue = Issue(title: "Hello, World!", createdAt: Date(), rating: 0)
        request = request.requestByReplacing(requestType: .JSONEncodable(issue))
        urlRequest = try! request.urlRequest()
        let expectedIssue = try! JSONDecoder().decode(Issue.self, from: urlRequest.httpBody!)
        XCTAssertEqual(issue.createdAt, expectedIssue.createdAt)
        XCTAssertEqual(issue.title, expectedIssue.title)
    }
    
    func test_request_type_jsonencodable_updates_headers_to_add_contenttype_json_but_no_other_properties() {
        var issue: Issue!
        var urlRequest: URLRequest!
        issue = Issue(title: "Hello, World!", createdAt: Date(), rating: 0)
        request = request.requestByReplacing(requestType: .JSONEncodable(issue))
        urlRequest = try! request.urlRequest()
        let contentTypeHeaders = ["Content-Type": "application/json"]
        let initialHeaderFields = request.headers ?? [:]
        let expectedHeaderFields = initialHeaderFields.merging(contentTypeHeaders) { initialValue, _ in
            initialValue
        }
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, expectedHeaderFields)
        XCTAssertEqual(urlRequest.url?.absoluteString, request.url)
        XCTAssertEqual(urlRequest.httpMethod, request.method.rawValue)
    }

    func test_request_type_customJsonEncodable_updates_body() {
        var issue: Issue!
        var urlRequest: URLRequest!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(formatter)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        issue = Issue(title: "Hello, World!", createdAt: Date(), rating: 0)
        request = request.requestByReplacing(requestType: .customJSONEncodable(issue, encoder: encoder))
        urlRequest = try! request.urlRequest()
        let expectedIssue = try! decoder.decode(Issue.self, from: urlRequest.httpBody!)
        XCTAssertEqual(formatter.string(from: issue.createdAt), formatter.string(from: expectedIssue.createdAt))
        XCTAssertEqual(issue.title, expectedIssue.title)
    }

    func test_request_type_customJsonEncodable_updates_headers_to_add_contenttype_json_but_no_other_properties() {
        var issue: Issue!
        var urlRequest: URLRequest!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(formatter)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        issue = Issue(title: "Hello, World!", createdAt: Date(), rating: 0)
        request = request.requestByReplacing(requestType: .customJSONEncodable(issue, encoder: encoder))
        urlRequest = try! request.urlRequest()
        let contentTypeHeaders = ["Content-Type": "application/json"]
        let initialHeaderFields = request.headers ?? [:]
        let expectedHeaderFields = initialHeaderFields.merging(contentTypeHeaders) { initialValue, _ in
            initialValue
        }
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, expectedHeaderFields)
        XCTAssertEqual(urlRequest.url?.absoluteString, request.url)
        XCTAssertEqual(urlRequest.httpMethod, request.method.rawValue)
    }

    func test_request_type_compositedata_updates_url_and_body_but_not_the_rest() {
        var parameters: [String: Any]!
        var data: Data!
        var urlRequest: URLRequest!
        parameters = ["Baddie": "DarthVader"]
        data = "test data".data(using: .utf8)
        request = request.requestByReplacing(requestType: .compositeData(bodyData: data, urlParameters: parameters))
        urlRequest = try! request.urlRequest()
        let expectedUrl = request.url + "?Baddie=DarthVader"
        XCTAssertEqual(urlRequest.url?.absoluteString, expectedUrl)
        XCTAssertEqual(urlRequest.httpBody, data)
        XCTAssertEqual(urlRequest.httpMethod, request.method.rawValue)
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, request.headers)
    }

    func test_request_type_compositeparameters_updates_request_and_url() {
        var bodyParameters: [String: Any]!
        var urlParameters: [String: Any]!
        var encoding: ParameterEncodingType!
        var urlRequest: URLRequest!
        bodyParameters = ["Baddie": "DarthVader"]
        urlParameters = ["DarthVader": "Baddie"]
        encoding = JSONEncoding.default
        request = request.requestByReplacing(requestType: .compositeParameters(bodyParameters: bodyParameters, bodyEncoding: encoding, urlParameters: urlParameters))
        urlRequest = try! request.urlRequest()
        let expectedUrl = request.url + "?DarthVader=Baddie"
        XCTAssertEqual(urlRequest.url?.absoluteString, expectedUrl)
        let newRequest = request.requestByReplacing(requestType: .plain)
        let newUrlRequest = try! newRequest.urlRequest()
        let newEncodedRequest = try? encoding.encode(newUrlRequest, with: bodyParameters)
        XCTAssertEqual(urlRequest.httpBody, newEncodedRequest?.httpBody)
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, newEncodedRequest?.allHTTPHeaderFields)
        XCTAssertEqual(urlRequest.httpMethod, newEncodedRequest?.httpMethod)
    }

    func test_url_invalid_throws_requestMapping_error() {
        let badRequest = Request(url: "invalid URL", sampleResponse: { .networkResponse(statusCode: 200, data: Data()) }, method: .get, requestType: .plain, headers: nil)
        var recievedError: MockingbirdError?
        do {
            _ = try badRequest.urlRequest()
        } catch {
            recievedError = error as? MockingbirdError
            XCTAssertNotNil(recievedError)
            if case .requestMapping(let message) = recievedError! {
                XCTAssertEqual(message, "invalid URL")
            } else {
                XCTFail("Not the expected error")
            }
        }
    }

    func test_jsonencoder_incorrect_parameters_returns_error_encodableMapping() {
        let encoder = JSONEncoder()
        let issue = Issue(title: "Hello, World!", createdAt: Date(), rating: Float.infinity)
        request = request.requestByReplacing(requestType: .customJSONEncodable(issue, encoder: encoder))
        let expectedError = EncodingError.invalidValue(Float.infinity, EncodingError.Context(codingPath: [Issue.CodingKeys.rating], debugDescription: "Unable to encode Float.infinity directly in JSON. Use JSONEncoder.NonConformingFloatEncodingStrategy.convertToString to specify how the value should be encoded.", underlyingError: nil))
        var recievedError: MockingbirdError?
        do {
            _ = try request.urlRequest()
        } catch {
            recievedError = error as? MockingbirdError
            XCTAssertNotNil(recievedError)
            if case .encodableMapping(let error) = recievedError! {
                let encodingError = error as? EncodingError
                XCTAssertNotNil(encodingError)
                XCTAssertEqual(encodingError?.localizedDescription, expectedError.localizedDescription)
            } else {
                XCTFail("Not the expected error")
            }
        }
    }
}

extension RequestTests {
    static var allTests = [
        ("test_adding_new_header_creates_new_endpoint", test_adding_new_header_creates_new_endpoint),
        ("test_returns_nil_urlrequest_for_invalid_url", test_returns_nil_urlrequest_for_invalid_url),
        ("test_request_type_plain_endpoint_with_request_not_changed", test_request_type_plain_endpoint_with_request_not_changed),
        ("test_request_type_parameters_endpoint_encoded_parameters", test_request_type_parameters_endpoint_encoded_parameters),
        ("test_request_type_data_updated_httpbody_but_not_other_properties", test_request_type_data_updated_httpbody_but_not_other_properties),
        ("test_request_type_jsonencodable_updates_body", test_request_type_jsonencodable_updates_body),
        ("test_request_type_jsonencodable_updates_headers_to_add_contenttype_json_but_no_other_properties", test_request_type_jsonencodable_updates_headers_to_add_contenttype_json_but_no_other_properties),
        ("test_request_type_customJsonEncodable_updates_body", test_request_type_customJsonEncodable_updates_body),
        ("test_request_type_customJsonEncodable_updates_headers_to_add_contenttype_json_but_no_other_properties", test_request_type_customJsonEncodable_updates_headers_to_add_contenttype_json_but_no_other_properties),
        ("test_request_type_compositedata_updates_url_and_body_but_not_the_rest", test_request_type_compositedata_updates_url_and_body_but_not_the_rest),
        ("test_request_type_compositeparameters_updates_request_and_url", test_request_type_compositeparameters_updates_request_and_url),
        ("test_url_invalid_throws_requestMapping_error", test_url_invalid_throws_requestMapping_error),
        ("test_jsonencoder_incorrect_parameters_returns_error_encodableMapping", test_jsonencoder_incorrect_parameters_returns_error_encodableMapping)
    ]
}
