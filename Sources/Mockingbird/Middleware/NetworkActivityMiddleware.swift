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

/// Possible states of the network activity
///
/// - began: A network interaction has started
/// - ended: A network interaction has finished
public enum NetworkActivityStatus {
    case began, ended
}

public final class NetworkActivityMiddleware: MiddlewareType {

    /// Typealias defining a function from `NetworkActivityStatus` and `RemoteServiceType` to Void
    public typealias NetworkActivityLambda = (_ status: NetworkActivityStatus, _ endpoint: RemoteServiceType) -> Void

    /// Function to be executed every time the network activity state
    /// changes
    let networkActivityLambda: NetworkActivityLambda

    public init(networkActivityLambda: @escaping NetworkActivityLambda) {
        self.networkActivityLambda = networkActivityLambda
    }

    // MARK: - MiddlewareType

    public func willSend(_ request: URLRequest, endpoint: RemoteServiceType) {
        networkActivityLambda(.began, endpoint)
    }

    public func didReceive(_ result: Result<Response, MockingbirdError>, endpoint: RemoteServiceType) {
        networkActivityLambda(.ended, endpoint)
    }
}
