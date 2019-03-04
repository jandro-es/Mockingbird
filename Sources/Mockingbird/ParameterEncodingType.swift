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

public typealias Parameters = [String: Any]

/// Protocol to define how to encode a collection of parameters for an `URLRequest`
public protocol ParameterEncodingType {

    /// Creates a new `URLRequest` after encoding the given parameters and adding them to
    /// an existing `URLRequest`
    ///
    /// - Parameters:
    ///   - urlRequest: The `URLRequest` to modify by adding the new parameters
    ///   - parameters: The collection of `Parameters` to add
    /// - Returns: The new `URLRequest` with the given parameters
    /// - Throws: MockingbirdError.parameterEncoding
    func encode(_ urlRequest: URLRequest, with parameters: Parameters?) throws -> URLRequest
}

/// Encodes a set of parameters into a url encodes query string that can be set or appended to any existing `URLRequest`. It
/// can added to the URL's query string or set as the HTTP body. The `Content-Type` HTTP header of a `URLRequest` when encoding
/// into the HTTP body will be set to `application/x-www-form-urlencoded; charset=utf-8`.
/// For arrays we use an encoding following the pattern of `foo[]=1&foo[]=2` and for dictionaries we use `foo[bar]=baz`. If
/// `ArrayEncoding` is used it omits the `[]` in the keys. By default we encode `Bool` as `true` for 1 and `false` for 0. If
// it needs to be customised `BoolEncoding` can be used.
public struct URLEncoding: ParameterEncodingType {

    /// Defines how to apply the url encoded query string to the `URLRequest`
    ///
    /// - methodDependent: Adds it as a query string for `GET`, `HEAD` and `DELETE`, HTTP body for the rest
    /// - queryString: Adds it as a query string to the URL
    /// - httpBody: Add it as HTTP body
    public enum Destination {

        case methodDependent, queryString, httpBody
    }

    /// Defines how array parameters are added to the query string
    ///
    /// - brackets: It uses empty brackets `[]` after the key, this is the default
    /// - noBrackets: It doesn't add any brackers, just the key itself
    public enum ArrayEncoding {

        case brackets, noBrackets

        func encode(key: String) -> String {
            switch self {
            case .brackets:
                return "\(key)[]"
            case .noBrackets:
                return key
            }
        }
    }

    /// Defines how boolean parameters are added to the query string
    ///
    /// - numeric: As it's numeric value, 1 for true and 0 for false
    /// - literal: As string representation, this is the default
    public enum BoolEncoding {
        case numeric, literal

        func encode(value: Bool) -> String {
            switch self {
            case .numeric:
                return value ? "1" : "0"
            case .literal:
                return value ? "true" : "false"
            }
        }
    }

    /// Returns a `default` instance
    public static var `default`: URLEncoding {
        return URLEncoding()
    }

    /// Returns an instance with a `.methodDependent` encoding destination
    public static var methodDependent: URLEncoding {
        return URLEncoding()
    }

    /// Returns an instance with a `.queryString` encoding destination
    public static var queryString: URLEncoding {
        return URLEncoding(destination: .queryString)
    }

    /// Returns an instance with an `.httpBody` encoding destination
    public static var httpBody: URLEncoding {
        return URLEncoding(destination: .httpBody)
    }

    /// The `Destination` to where to apply the encoded query string
    public let destination: Destination

    /// The encoding to use for array parameters
    public let arrayEncoding: ArrayEncoding

    /// The encoding to use for boolean parameters
    public let boolEncoding: BoolEncoding

    /// Initializes an instance of `URLEncoding` with the given pameters
    ///
    /// - Parameters:
    ///   - destination: The `Destination` where to apply the encoding query string, `MethodDependent` as default
    ///   - arrayEncoding: How to encode array parameters, `Brackets` as default
    ///   - boolEncoding: How to encode boolean parameters, `Numeric` as default
    public init(destination: Destination = .methodDependent, arrayEncoding: ArrayEncoding = .brackets, boolEncoding: BoolEncoding = .numeric) {
        self.destination = destination
        self.arrayEncoding = arrayEncoding
        self.boolEncoding = boolEncoding
    }

    /// Creates a new `URLRequest` after encoding the given parameters and adding them to
    /// an existing `URLRequest`
    ///
    /// - Parameters:
    ///   - urlRequest: The `URLRequest` to modify by adding the new parameters
    ///   - parameters: The collection of `Parameters` to add
    /// - Returns: The new `URLRequest` with the given parameters
    /// - Throws: MockingbirdError.parameterEncoding
    public func encode(_ urlRequest: URLRequest, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = urlRequest

        guard let parameters = parameters else { return urlRequest }

        if let method = HTTPMethod(rawValue: urlRequest.httpMethod ?? "GET"), encodesParametersInURL(with: method) {
            guard let url = urlRequest.url else {
                throw MockingbirdError.parameterEncoding(reason: .missingURL)
            }

            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
                let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
                urlComponents.percentEncodedQuery = percentEncodedQuery
                urlRequest.url = urlComponents.url
            }
        } else {
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            }

            urlRequest.httpBody = Data(query(parameters).utf8)
        }

        return urlRequest
    }

    /// Creates, by using recursion, percent scaped, URL encoded, query string components from the
    /// given key value pairs
    ///
    /// - Parameters:
    ///   - key: The key of the query component
    ///   - value: The value of the query component
    /// - Returns: The percent escaped URL encoded query string components
    public func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []

        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: arrayEncoding.encode(key: key), value: value)
            }
        } else if let value = value as? NSNumber {
            if value.isBool {
                components.append((escape(key), escape(boolEncoding.encode(value: value.boolValue))))
            } else {
                components.append((escape(key), escape("\(value)")))
            }
        } else if let bool = value as? Bool {
            components.append((escape(key), escape(boolEncoding.encode(value: bool))))
        } else {
            components.append((escape(key), escape("\(value)")))
        }

        return components
    }

    /// Returns a percent encoded string
    ///
    /// - Parameter string: The string to encode
    /// - Returns: A percent encoded string
    public func escape(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }

    /// Returns a query string with `&` as joining characters
    /// form a collection of parameters
    ///
    /// - Parameter parameters: The parameters to add to the query string
    /// - Returns: The query string
    private func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []

        for key in parameters.keys.sorted(by: <) {
            if let value = parameters[key] {
                components += queryComponents(fromKey: key, value: value)
            }
        }
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }

    /// Private method to decide, depending in the HTTP method if the encoded query string
    /// goes into the URL or not
    ///
    /// - Parameter method: The HTTPMethod
    /// - Returns: If it need to be applied to the URL or not
    private func encodesParametersInURL(with method: HTTPMethod) -> Bool {
        switch destination {
        case .queryString:
            return true
        case .httpBody:
            return false
        default:
            break
        }

        switch method {
        case .get, .head, .delete:
            return true
        default:
            return false
        }
    }
}

/// Using `JSONSerialization` create a JSON object from the collection of parameters and sets it as
/// the body of the request. The `Content-Type` HTTP header is set to `application/json`
public struct JSONEncoding: ParameterEncodingType {

    /// Returns an instance with default JSON writing options
    public static var `default`: JSONEncoding {
        return JSONEncoding()
    }

    /// Returns an instance with `.prettyPrinted` writing options
    public static var prettyPrinted: JSONEncoding {
        return JSONEncoding(options: .prettyPrinted)
    }

    /// The `JSONSerialization.WritingOptions` to use when writin the JSON
    public let options: JSONSerialization.WritingOptions

    /// Initialises an instance with the given `JSONSerialization.WritingOptions` option, empty as default
    ///
    /// - Parameter options: `JSONSerialization.WritingOptions` used to write
    public init(options: JSONSerialization.WritingOptions = []) {
        self.options = options
    }

    /// Creates a new `URLRequest` after encoding the given parameters and adding them to
    /// an existing `URLRequest`
    ///
    /// - Parameters:
    ///   - urlRequest: The `URLRequest` to modify by adding the new parameters
    ///   - parameters: The collection of `Parameters` to add
    /// - Returns: The new `URLRequest` with the given parameters
    /// - Throws: MockingbirdError.parameterEncoding
    public func encode(_ urlRequest: URLRequest, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = urlRequest

        guard let parameters = parameters else { return urlRequest }

        do {
            let data = try JSONSerialization.data(withJSONObject: parameters, options: options)

            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }

            urlRequest.httpBody = data
        } catch {
            throw MockingbirdError.parameterEncoding(reason: .jsonEncodingFailed(error: error))
        }

        return urlRequest
    }

    /// Creates a new `URLRequest` after encoding the given JSON object and adding it to
    /// an existing `URLRequest`
    ///
    /// - Parameters:
    ///   - urlRequest: The `URLRequest` to modify by adding the new parameters
    ///   - jsonObject: The JSON object to encode and add
    /// - Returns: The new `URLRequest` with the given parameters
    /// - Throws: MockingbirdError.parameterEncoding
    public func encode(_ urlRequest: URLRequest, withJSONObject jsonObject: Any? = nil) throws -> URLRequest {
        var urlRequest = urlRequest

        guard let jsonObject = jsonObject else { return urlRequest }

        do {
            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: options)

            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }

            urlRequest.httpBody = data
        } catch {
            throw MockingbirdError.parameterEncoding(reason: .jsonEncodingFailed(error: error))
        }

        return urlRequest
    }
}

extension NSNumber {

    /// Helper property for transformming an NSNumber boolean into a swfit Bool
    fileprivate var isBool: Bool {
        return CFBooleanGetTypeID() == CFGetTypeID(self)
    }
}
