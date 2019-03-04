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

/// Supported `Request` types
///
/// - plain: Simple `Request`
/// - data: The `Request` has a body with `Data`
/// - JSONEncodable: The `Request` has a body with an `Encodable` object
/// - customJSONEncodable: The `Request` has a body with an `Encodable` object using a custom `JSONEncoder`
/// - parameters: The request has a collection of URL parameters using a `ParameterEncodingType` as encoder
/// - compositeData: The request has a collection of URL parameters and a body with `Data` type
/// - compositeParameters: The request has a combination of body parameters (encoded as `Data`) and URL parameters
/// - download: The request is for downloading a file
/// - downloadParameters: The request is for downloading a file with URL parameters
public enum RequestType: CustomDebugStringConvertible {

    case plain

    case data(Data)

    case JSONEncodable(Encodable)

    case customJSONEncodable(Encodable, encoder: JSONEncoder)

    case parameters(parameters: [String: Any], encoding: ParameterEncodingType)

    case compositeData(bodyData: Data, urlParameters: [String: Any])

    case compositeParameters(bodyParameters: [String: Any], bodyEncoding: ParameterEncodingType, urlParameters: [String: Any])

    case download(DownloadCompletionLambda)

    case downloadParameters(parameters: [String: Any], encoding: ParameterEncodingType, destination: DownloadCompletionLambda)

    public var debugDescription: String {
        switch self {
        case .plain:
            return "plain"
        case .data:
            return "data"
        case .JSONEncodable:
            return "JSONEncodable"
        case .customJSONEncodable:
            return "customJSONEncodable"
        case .parameters:
            return "parameters"
        case .compositeData:
            return "compositeData"
        case .compositeParameters:
            return "compositeParameters"
        case .download:
            return "download"
        case .downloadParameters:
            return "downloadParameters"
        }
    }
}
