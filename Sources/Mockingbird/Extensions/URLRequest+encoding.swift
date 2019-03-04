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

internal extension URLRequest {

    /// Modifies the current `URLRequest` by encoding the passed `Encodable` type
    /// using the given `JSONEncoder` and adding it to the `httpBody` of the `URLRequest`.
    /// At the same type automatically adds the `Content-Type: application/json` header given
    /// that only JSON content type is supported.
    ///
    /// - Parameters:
    ///   - encodable: The `Encodable` type to add to the request
    ///   - encoder: The `JSONEncoder` to use, it defaults to `JSONEncoder`
    /// - Returns: The modified `URLRequest`
    /// - Throws: MockingbirdError.encodableMapping
    mutating func encoded(encodable: Encodable, encoder: JSONEncoder = JSONEncoder()) throws -> URLRequest {
        do {
            let encodable = AnyEncodable(encodable)
            httpBody = try encoder.encode(encodable)
            let contentTypeHeaderName = "Content-Type"
            if value(forHTTPHeaderField: contentTypeHeaderName) == nil {
                setValue("application/json", forHTTPHeaderField: contentTypeHeaderName)
            }
            return self
        } catch {
            throw MockingbirdError.encodableMapping(error)
        }
    }

    /// Returns a new `URLRequest` by encoding the passed paramenters, using
    /// the give `ParameterEncodingType` and adding them to the current `URLRequest`.
    ///
    /// - Parameters:
    ///   - parameters: The parameters to add
    ///   - parameterEncoding: The `ParameterEncodingType` to use
    /// - Returns: A new `URLRequest` copied from the current one and adding the parameters
    /// - Throws: MockingbirdError.parameterEncoding
    func encoded(parameters: [String: Any], parameterEncoding: ParameterEncodingType) throws -> URLRequest {
        do {
            return try parameterEncoding.encode(self, with: parameters)
        } catch let error {
            throw MockingbirdError.parameterEncoding(reason: .jsonEncodingFailed(error: error))
        }
    }
}
