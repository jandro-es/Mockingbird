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

/// Defines a `Middleware` type that can be used to modify, notify, track, etc. the
/// actual requests of `Mockingbird`
public protocol MiddlewareType {

    /// Called before sending and once the the `URLRequest` has been created. It can
    /// be used to modify said `URLRequest` before sending. Commonly used to add
    /// Auth header and similar.
    ///
    /// - Parameters:
    ///   - request: The `URLRequest` generated
    ///   - endpoint: The endpoint of a `RemoteServiceType`
    /// - Returns: The modified `URLRequest`
    func prepare(_ request: URLRequest, endpoint: RemoteServiceType) -> URLRequest

    /// Called immediately before a request is send or stubbed. Commonly used
    /// for adding tracking, notify the UI, etc. The `URLRequest` should not
    /// be modified at this point.
    ///
    /// - Parameters:
    ///   - request: The `URLRequest` that is going to be sent
    ///   - endpoint: The endpoint of a `RemoteServiceType`
    func willSend(_ request: URLRequest, endpoint: RemoteServiceType)

    /// It's called just after receiving a response, but before anything is processed. Commonly used
    /// to add tracking, notify the UI when the actual network operation has finished, etc. It's a bad practice
    /// to modify the response at this point, it can cause very difficult to trace bugs.
    ///
    /// - Parameters:
    ///   - result: The `Result` type of the response
    ///   - endpoint: The endpoint of a `RemoteServiceType` that generated the request
    func didReceive(_ result: Result<Response, MockingbirdError>, endpoint: RemoteServiceType)

    /// It's called after `didReceive` but before the completion lambda is executed. Use this method if you
    /// need to modify the `Result`.
    ///
    /// - Parameters:
    ///   - result: The `Result` type of the response
    ///   - collection: The endpoint of a `RemoteServiceType` that generated the request
    /// - Returns: A modified, if wanted, `Result` type
    func process(_ result: Result<Response, MockingbirdError>, endpoint: RemoteServiceType) -> Result<Response, MockingbirdError>
}

// MARK: - Default implementation

public extension MiddlewareType {

    func prepare(_ request: URLRequest, endpoint: RemoteServiceType) -> URLRequest {
        return request
    }

    func willSend(_ request: URLRequest, endpoint: RemoteServiceType) { }

    func didReceive(_ result: Result<Response, MockingbirdError>, endpoint: RemoteServiceType) { }

    func process(_ result: Result<Response, MockingbirdError>, endpoint: RemoteServiceType) -> Result<Response, MockingbirdError> {
        return result
    }
}
