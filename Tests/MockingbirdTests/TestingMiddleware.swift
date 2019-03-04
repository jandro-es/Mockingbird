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
import enum Result.Result
@testable import Mockingbird

final class TestingMiddleware: MiddlewareType {
    var request: (URLRequest, RemoteServiceType)?
    var result: Result<Response, MockingbirdError>?
    var didPrepare = false

    func prepare(_ request: URLRequest, endpoint: RemoteServiceType) -> URLRequest {
        var request = request
        request.addValue("yes", forHTTPHeaderField: "prepared")
        return request
    }

    func willSend(_ request: URLRequest, endpoint: RemoteServiceType) {
        self.request = (request, endpoint)
        // We check for whether or not we did prepare here to make sure prepare gets called
        // before willSend
        didPrepare = request.allHTTPHeaderFields?["prepared"] == "yes"
    }

    func didReceive(_ result: Result<Response, MockingbirdError>, endpoint: RemoteServiceType) {
        self.result = result
    }

    func process(_ result: Result<Response, MockingbirdError>, endpoint: RemoteServiceType) -> Result<Response, MockingbirdError> {
        var result = result
        if case .success(let response) = result {
            let processedResponse = Response(statusCode: -1, data: response.data, urlRequest: response.request, response: response.response)
            result = .success(processedResponse)
        }
        return result
    }
}
