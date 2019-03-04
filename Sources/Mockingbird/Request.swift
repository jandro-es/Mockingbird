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

import Foundation
import os

/// Encapsulates everything needed to perform an actual request
/// to the service.
open class Request {

    /// Typealias for a function returning a `RequestSampleResponse`
    public typealias SampleResponse = () -> RequestSampleResponse

    /// Stores the full URL for the request
    public let url: String

    /// Stores the `HTTPMethod` to use for the request
    public let method: HTTPMethod

    /// Stores the `RequestType` to use for the request
    public let requestType: RequestType

    /// Stores the optional `HTTPHeaders` to use in the request
    public let headers: HTTPHeaders?

    /// Stores a function used to generate a `RequestSampleResponse`
    public let sampleResponse: SampleResponse

    // MARK: - Initializers

    public init(url: String, sampleResponse: @escaping SampleResponse, method: HTTPMethod, requestType: RequestType, headers: HTTPHeaders?) {
        self.url = url
        self.sampleResponse = sampleResponse
        self.method = method
        self.requestType = requestType
        self.headers = headers
        if #available(iOS 10, OSX 10.12, *) {
            os_log("Request created for the url: %@ %@ of type %@ with headers %@", log: OSLog.request, type: .debug, method.rawValue, url, requestType.debugDescription, headers ?? "")
        }
    }

    // MARK: - Open methods

    /// Returns a new `Request` with the same properties as the current one plus the new added `HTTPHeaders`
    ///
    /// - Parameter headers: The `HTTPHeaders` to add to the new `Request`
    /// - Returns: The newly created `Request`
    open func requestByAdding(headers: HTTPHeaders) -> Request {
        return Request(url: self.url, sampleResponse: self.sampleResponse, method: self.method, requestType: self.requestType, headers: add(headers: headers))
    }

    /// Returns a new `Request` with the same properties as the current one, but replacing the `RequestType` with
    /// the new one.
    ///
    /// - Parameter requestType: The `RequestType` for the new `Request`
    /// - Returns: The newly created `Request
    open func requestByReplacing(requestType: RequestType) -> Request {
        return Request(url: self.url, sampleResponse: self.sampleResponse, method: self.method, requestType: requestType, headers: headers)
    }

    // MARK: - Private methods

    /// Returns a new collection of `HTTPHeaders` by adding the passed ones to the ones
    /// in the `Request`. If there are no specific headers in the `Request` it
    /// just return the passed ones.
    ///
    /// - Parameter headers: The headers to add to the current ones
    /// - Returns: The collection of headers after adding the new ones
    fileprivate func add(headers newHeaders: HTTPHeaders) -> HTTPHeaders {
        guard let headers = headers, !headers.isEmpty else {
            return newHeaders
        }
        var fullHeaders = headers
        newHeaders.forEach { key, value in
            fullHeaders[key] = value
        }
        return fullHeaders
    }
}

extension Request {

    /// Tries to convert the Request into a Foundation's `URLRequest` and returns it, throws an error otherwise. Based
    /// on the type of the request it composes it with values especified.
    ///
    /// - Returns: The converterd `URLRequest`
    /// - Throws: MockingbirdError.requestMapping
    public func urlRequest() throws -> URLRequest {
        guard let requestURL = Foundation.URL(string: url) else {
            if #available(iOS 10, OSX 10.12, *) {
                os_log("Impossible to create an URL instance from the string %@", log: OSLog.request, type: .error, url)
            }
            throw MockingbirdError.requestMapping(url)
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers

        switch requestType {
        case .plain, .download:
            return request
        case .data(let data):
            request.httpBody = data
            return request
        case let .JSONEncodable(encodable):
            return try request.encoded(encodable: encodable)
        case let .customJSONEncodable(encodable, encoder: encoder):
            return try request.encoded(encodable: encodable, encoder: encoder)
        case let .parameters(parameters, parameterEncoding):
            if #available(iOS 10, OSX 10.12, *) {
                os_log("Request of type .parameters with parameters %@", log: OSLog.request, type: .debug, parameters)
            }
            return try request.encoded(parameters: parameters, parameterEncoding: parameterEncoding)
        case let .compositeData(bodyData: bodyData, urlParameters: urlParameters):
            request.httpBody = bodyData
            let parameterEncoding = URLEncoding(destination: .queryString)
            if #available(iOS 10, OSX 10.12, *) {
                os_log("Request of type .compositeData with parameters %@", log: OSLog.request, type: .debug, urlParameters)
            }
            return try request.encoded(parameters: urlParameters, parameterEncoding: parameterEncoding)
        case let .compositeParameters(bodyParameters: bodyParameters, bodyEncoding: bodyParameterEncoding, urlParameters: urlParameters):
            if let bodyParameterEncoding = bodyParameterEncoding as? URLEncoding, bodyParameterEncoding.destination != .httpBody {
                fatalError("The only encoding that `bodyEncoding` accepts is .httpBody")
            }
            let bodyfulRequest = try request.encoded(parameters: bodyParameters, parameterEncoding: bodyParameterEncoding)
            let urlEncoding = URLEncoding(destination: .queryString)
            if #available(iOS 10, OSX 10.12, *) {
                os_log("Request of type .compositeParameters with parameters %@", log: OSLog.request, type: .debug, urlParameters)
            }
            return try bodyfulRequest.encoded(parameters: urlParameters, parameterEncoding: urlEncoding)
        case let .downloadParameters(parameters, parameterEncoding, _):
            if #available(iOS 10, OSX 10.12, *) {
                os_log("Request of type .downloadParameters with parameters $%", log: OSLog.request, type: .debug, parameters)
            }
            return try request.encoded(parameters: parameters, parameterEncoding: parameterEncoding)
        }
    }
}


// MARK: - Hashable

extension Request: Hashable {

    // swiftlint:disable legacy_hashing
    public var hashValue: Int {
        let request = try? urlRequest()
        return request?.hashValue ?? url.hashValue
    }
}

// MARK: - Equatable

extension Request: Equatable {

    /// For testing equality it tries to get the `URLRequest` of each of the
    /// `Request` objects and compare them. If both of them are nil, it compares
    /// the `HashValue` of each `Request` as defined in the compliance to the
    /// `Hashable` protocol
    ///
    /// - Parameters:
    ///   - lhs: One `Request` instance
    ///   - rhs: Other `Request` instance
    /// - Returns: If both instances are equal or not
    public static func == (lhs: Request, rhs: Request) -> Bool {
        let lhsRequest = try? lhs.urlRequest()
        let rhsRequest = try? rhs.urlRequest()
        if lhsRequest != nil, rhsRequest == nil {
            return false
        }
        if lhsRequest == nil, rhsRequest != nil {
            return false
        }
        if lhsRequest == nil, rhsRequest == nil {
            return lhs.hashValue == rhs.hashValue
        }
        return (lhsRequest == rhsRequest)
    }
}
