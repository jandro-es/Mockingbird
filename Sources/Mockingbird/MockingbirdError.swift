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

/// Defines the different possible errors of Mockingbird
///
/// - missingURL: `parameterEncoding` error when the URL is not present
/// - jsonEncodingFailed: `parameterEncoding` error when imposible to encode a JSON
/// - jsonMapping: Error mapping to a JSON object / collection
/// - stringMapping: Error mapping to a `String`
/// - decodableMapping: Error when mapping to a `decodable` object
/// - encodableMapping: Error when mapping to an `encodable` object
/// - invalidStatusCode: invalid status code returned (based on the status code validation)
/// - network: Network error (latency, no internet, etc.)
/// - requestMapping: Error trying to generate an `URLRequest`
/// - parameterEncoding: Error when encoding parameters
public enum MockingbirdError: Error {

    public enum ParameterEncodingFailureReason: Error {
        case missingURL
        case jsonEncodingFailed(error: Error)
    }

    // MARK: - Mapping errors

    case jsonMapping(Response)

    case stringMapping(Response)

    // MARK: - Encoding / Decoding errors

    case decodableMapping(Error, Response)

    // MARK: - Encoding errors

    case encodableMapping(Error)

    // MARK: - Network errors

    case invalidStatusCode(Response)

    case network(Error, Response?)

    // MARK: - Internal errors

    case requestMapping(String)

    case parameterEncoding(reason: ParameterEncodingFailureReason)
}

// MARK: - Response

public extension MockingbirdError {

    /// Depending in the type of error, it will
    /// return the `Response` object
    var response: Response? {
        switch self {
        case .jsonMapping(let response):
            return response
        case .stringMapping(let response):
            return response
        case .decodableMapping(_, let response):
            return response
        case .encodableMapping:
            return nil
        case .invalidStatusCode(let response):
            return response
        case .network(_, let response):
            return response
        case .requestMapping:
            return nil
        case .parameterEncoding:
            return nil
        }
    }
}

// MARK: - LocalizedError

extension MockingbirdError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .jsonMapping:
            return "Failed to map data to a JSON object / collection"
        case .stringMapping:
            return "Failed to map data to a String"
        case .decodableMapping(let error, _):
            return "Failed to map data to a Decodable object with error: \(error.localizedDescription)"
        case .encodableMapping(let error):
            return "Failed to encode Encodable object into data with error: \(error.localizedDescription)"
        case .invalidStatusCode(let response):
            return "Invalid status code: \(response.statusCode)"
        case .network(let error, _):
            return error.localizedDescription
        case .requestMapping:
            return "Failed to generate a URLRequest"
        case .parameterEncoding(let reason):
            return "Failed to encode parameters for URLRequest with error: \(reason.localizedDescription)"
        }
    }
}
