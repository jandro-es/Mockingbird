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

/// Types of sample responses
///
/// - networkResponse: There is a response, with status code and `Data`
/// - response: There is a response, with `HTTPURLResponse` and `Data` objects
/// - networkError: There is no response, it contains a `NSError`
public enum RequestSampleResponse {

    case networkResponse(statusCode: Int, data: Data)

    case response(response: HTTPURLResponse, data: Data)

    case networkError(error: NSError)
}

/// Object encapsulating an optional `HTTPURLResponse` from the network. It provides access
/// to everything needed like, status code, `Data`, the original `URLRequest` etc..
public final class Response: CustomDebugStringConvertible, Equatable {

    /// The returned HTTP Status Code
    public let statusCode: Int

    /// The returned `Data`
    public let data: Data

    /// The original `URLRequest`
    public let request: URLRequest?

    /// The returned `HTTPURLResponse`
    public let response: HTTPURLResponse?

    /// Initialises a `Response` object with the given values
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP Status Code
    ///   - data: The `Data` object
    ///   - urlRequest: An optional `URLRequest`
    ///   - response: An optiona `HTTPURLResponse`
    public init(statusCode: Int, data: Data, urlRequest: URLRequest? = nil, response: HTTPURLResponse? = nil) {
        self.statusCode = statusCode
        self.data = data
        self.request = urlRequest
        self.response = response
    }

    /// A String describing the `Response`
    public var description: String {
        return "Status Code: \(statusCode), Data Length: \(data.count)"
    }

    /// A String describing the `Response`
    public var debugDescription: String {
        return description
    }

    /// Equality operator
    ///
    /// - Parameters:
    ///   - lhs: A `Response` object
    ///   - rhs: Another `Response` object
    /// - Returns: If both `Response` objects are equal
    public static func == (lhs: Response, rhs: Response) -> Bool {
        return lhs.statusCode == rhs.statusCode && lhs.data == rhs.data && lhs.response == rhs.response
    }
}

public extension Response {

    /// Returns itself if the `Response` status code is contained in the given ones
    ///
    /// - Parameter statusCodes: A Collection of status codes to validate
    /// - Returns: The `Response` object if it's status code is contained in the given ones
    /// - Throws: MockingbirdError.invalidStatusCode
    func filter<R: RangeExpression>(statusCodes: R) throws -> Response where R.Bound == Int {
        guard statusCodes.contains(statusCode) else {
            throw MockingbirdError.invalidStatusCode(self)
        }
        return self
    }

    /// It returns itself if the status code is equal to the given one
    ///
    /// - Parameter statusCode: The status code to validate the response against
    /// - Returns: The `Response` object if it's status code is equal to the given one
    /// - Throws: MockingbirdError.invalidStatusCode
    func filter(statusCode: Int) throws -> Response {
        return try filter(statusCodes: statusCode...statusCode)
    }

    /// Returns itself if the status code is contained in the standard success codes
    ///
    /// - Returns: The `Response` object if it's status code is contained in standard success codes
    /// - Throws: MockingbirdError.invalidStatusCode
    func filterSuccessfulStatusCodes() throws -> Response {
        return try filter(statusCodes: 200...299)
    }

    /// Returns itself if the status code is contained in the standard success and redirect codes
    ///
    /// - Returns: The `Response` object if it's status code is contained in standard success and redirect codes
    /// - Throws: MockingbirdError.invalidStatusCode
    func filterSuccessfulStatusAndRedirectCodes() throws -> Response {
        return try filter(statusCodes: 200...399)
    }

    /// Internal method to map the received `Data` object into a `JSON` object
    ///
    /// - Parameter failsOnEmptyData: If the mapping should fail when `Data` is empty
    /// - Returns: `JSON` object as `Any`
    /// - Throws: JSONSerialization
    func mapJSON(failsOnEmptyData: Bool = true) throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            if data.count < 1 && !failsOnEmptyData {
                return NSNull()
            }
            throw MockingbirdError.jsonMapping(self)
        }
    }

    /// Function to map the received `Data` object into a `String`. It admits an optional `Keypath` string
    /// at start parsing to string. Used for responses like "values: []"
    ///
    /// - Parameter keyPath: Optional Keypath to start the parsing from
    /// - Returns: A `String`
    /// - Throws: MockingbirdError.stringMapping
    func mapString(at keyPath: String? = nil) throws -> String {
        if let keyPath = keyPath {
            // Key path was provided, try to parse string at key path
            guard let jsonDictionary = try mapJSON() as? NSDictionary,
                let string = jsonDictionary.value(forKeyPath: keyPath) as? String else {
                    throw MockingbirdError.stringMapping(self)
            }
            return string
        } else {
            // Key path was not provided, parse entire response as string
            guard let string = String(data: data, encoding: .utf8) else {
                throw MockingbirdError.stringMapping(self)
            }
            return string
        }
    }

    /// Internal method to map the recieved `Data` object into a `Decodable` object. It admits an optional `Keypath` string
    /// at start parsing to string. Used for responses like "values: []".
    ///
    /// - Parameters:
    ///   - type: The type of the `Decodable` object to map into
    ///   - keyPath: Optional Keypath to start the parsing from
    ///   - decoder: The `JSONDecoder` to use, it defaults to `JSONDecoder()`
    ///   - failsOnEmptyData: If the mapping should fail when `Data` is empty
    /// - Returns: An object of the given type
    /// - Throws: MockingbirdError.jsonMapping
    /// - Throws: MockingbirdError.decodableMapping
    func map<D: Decodable>(_ type: D.Type, at keyPath: String? = nil, using decoder: JSONDecoder = JSONDecoder(), failsOnEmptyData: Bool = true) throws -> D {
        let serializeToData: (Any) throws -> Data? = { (jsonObject) in
            guard JSONSerialization.isValidJSONObject(jsonObject) else {
                return nil
            }
            do {
                return try JSONSerialization.data(withJSONObject: jsonObject)
            } catch {
                throw MockingbirdError.jsonMapping(self)
            }
        }
        let jsonData: Data
        keyPathCheck: if let keyPath = keyPath {
            guard let jsonObject = (try mapJSON(failsOnEmptyData: failsOnEmptyData) as? NSDictionary)?.value(forKeyPath: keyPath) else {
                if failsOnEmptyData {
                    throw MockingbirdError.jsonMapping(self)
                } else {
                    jsonData = data
                    break keyPathCheck
                }
            }

            if let data = try serializeToData(jsonObject) {
                jsonData = data
            } else {
                let wrappedJsonObject = ["value": jsonObject]
                let wrappedJsonData: Data
                if let data = try serializeToData(wrappedJsonObject) {
                    wrappedJsonData = data
                } else {
                    throw MockingbirdError.jsonMapping(self)
                }
                do {
                    return try decoder.decode(DecodableWrapper<D>.self, from: wrappedJsonData).value
                } catch let error {
                    throw MockingbirdError.decodableMapping(error, self)
                }
            }
        } else {
            jsonData = data
        }
        do {
            if jsonData.count < 1 && !failsOnEmptyData {
                if let emptyJSONObjectData = "{}".data(using: .utf8), let emptyDecodableValue = try? decoder.decode(D.self, from: emptyJSONObjectData) {
                    return emptyDecodableValue
                } else if let emptyJSONArrayData = "[{}]".data(using: .utf8), let emptyDecodableValue = try? decoder.decode(D.self, from: emptyJSONArrayData) {
                    return emptyDecodableValue
                }
            }
            return try decoder.decode(D.self, from: jsonData)
        } catch let error {
            throw MockingbirdError.decodableMapping(error, self)
        }
    }
}

private struct DecodableWrapper<T: Decodable>: Decodable {
    let value: T
}
