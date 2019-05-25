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

public extension Mockingbird {

    /// Class method to generate a `default` mapping from and endpoint of a
    /// `RemoteServiceType` definition into a `Request` object
    ///
    /// - Parameter endpoint: The endpoint of a `RemoteServiceType`
    /// - Returns: A `Request` object mapped from said endpoint
    final class func defaultRequestMapping(for endpoint: RemoteService) -> Request {
        let sampleResponse: Request.SampleResponse = { .networkResponse(statusCode: 200, data: endpoint.testData) }
        return Request(url: URL(endpoint: endpoint).absoluteString, sampleResponse: sampleResponse, method: endpoint.method, requestType: endpoint.requestType, headers: endpoint.headers)
    }

    /// Class method to generate a `default` mapping from a `Request` applying the
    /// passed lambda and mapping the thrown error into a `RequestResultLambda` in case
    /// it fails.
    ///
    /// - Parameters:
    ///   - request: The `Request` to map
    ///   - lambda: The `RequestResultLambda` to apply to the `Request`
    /// - Throws:
    ///   - MockingbirdError.requestMapping
    ///   - MockingbirdError.parameterEncoding
    ///   - MockingbirdError.network
    final class func defaultRequestMapping(for request: Request, lambda: RequestResultLambda) {
        do {
            let urlRequest = try request.urlRequest()
            lambda(.success(urlRequest))
        } catch MockingbirdError.requestMapping(let url) {
            lambda(.failure(MockingbirdError.requestMapping(url)))
        } catch MockingbirdError.parameterEncoding(let error) {
            lambda(.failure(MockingbirdError.parameterEncoding(reason: .jsonEncodingFailed(error: error))))
        } catch {
            lambda(.failure(MockingbirdError.network(error, nil)))
        }
    }

    /// The default `URLSessionConfiguration` for `Mockingbird`
    ///
    /// - Returns: URLSessionConfiguration.default
    final class func defaultConfiguration() -> URLSessionConfiguration {
        return URLSessionConfiguration.default
    }
}
