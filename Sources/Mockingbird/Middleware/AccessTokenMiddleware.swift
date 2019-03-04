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

/// Protocol to specify that a `RemoteServiceType` uses `AccessToken`
/// for authorization, and the specific type of token required. Only
/// one type of token per service is supported.
public protocol AccessTokenAuthorizable {

    /// The specific type of token required by the `RemoteServiceType`
    var accessTokenType: AccessTokenType { get }
}

/// Supported types of AccessTokens
///
/// - none: No AccessToken
/// - basic: `Basic` AccessToken
/// - bearer: `Bearer` AccessToken
/// - custom: `custom` AccessToken
public enum AccessTokenType {
    case none
    case basic
    case bearer
    case custom(String)

    public var value: String? {
        switch self {
        case .none:
            return nil
        case .basic:
            return "Basic"
        case .bearer:
            return "Bearer"
        case .custom(let customString):
            return customString
        }
    }
}

/// Middleware object to manage AccessToken for a `RemoteService`
public final class AccessTokenMiddleware: MiddlewareType {

    /// Function to retrieve / compute the AccessToken
    public let tokenLambda: () -> String

    /// Creates an instance of `AccessTokenMiddleware` with the given function
    /// to retrieve / compute the AccessToken
    ///
    /// - Parameter tokenLambda: The function to retrieve / compute the token
    init(tokenLambda: @escaping () -> String) {
        self.tokenLambda = tokenLambda
    }

    // MARK: - MiddlewareType

    /// Modifies an `URLRequest` before it gets used. if the `endpoint` used is `AccessTokenAuthorizable`
    /// and based in the type of access token declared, adds the needed `Authorization` header with the
    /// computed value from the `tokenLambda`.
    ///
    /// - Parameters:
    ///   - request: The `URLRequest` to modify
    ///   - endpoint: The `RemoteServiceType` endpoint to use
    /// - Returns: The modified `URLRequest`
    public func prepare(_ request: URLRequest, endpoint: RemoteServiceType) -> URLRequest {
        guard let authorizable = endpoint as? AccessTokenAuthorizable else {
            if #available(iOS 10, OSX 10.12, *) {
                os_log("Request %@ does not conform to AccessTokenAuthorizable", log: OSLog.middleware, type: .error, endpoint.path)
            }
            return request
        }
        var request = request
        switch authorizable.accessTokenType {
        case .basic, .bearer, .custom:
            if let value = authorizable.accessTokenType.value {
                let authValue = value + " " + tokenLambda()
                request.addValue(authValue, forHTTPHeaderField: "Authorization")
                if #available(iOS 10, OSX 10.12, *) {
                    os_log("Added Authorization header of type %@ to the request %@ ", log: OSLog.middleware, type: .debug, value, endpoint.path)
                }
            }
        case .none:
            break
        }
        return request
    }
}
