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

/// Describes a Remote Service with all the information
/// needed by a `Mockingbird` instance to perform requests to it.
public protocol RemoteServiceType {

    /// The base `URL` of the service
    var baseURL: URL { get }

    /// The full path of the request, it will
    /// be added to the `baseURL`
    var path: String { get }

    /// Which `HTTPMethod` said request should use
    var method: HTTPMethod { get }

    /// Sample data used in testing and to mock
    /// the response
    var testData: Data { get }

    /// Which type of request should it be
    var requestType: RequestType { get }

    /// Which validation should be used for the response
    var validation: RequestValidation { get }

    /// Collection of `HTTPHeaders` used in the request
    var headers: HTTPHeaders? { get }
}
