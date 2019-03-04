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
import Mockingbird

func delayExecution(_ delay: TimeInterval, block: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
}

func url(_ endpoint: RemoteServiceType) -> String {
    return endpoint.baseURL.appendingPathComponent(endpoint.path).absoluteString
}

let failureRequestLambda = { (endpoint: GitHub) -> Request in
    let error = NSError(domain: "com.mockingbird.mockingbirderror", code: 0, userInfo: [NSLocalizedDescriptionKey: "I am error"])
    return Request(url: url(endpoint), sampleResponse: {.networkError(error: error)}, method: endpoint.method, requestType: endpoint.requestType, headers: endpoint.headers)
}

// MARK: - Mocks

enum GitHub {
    case zen
    case userProfile(String)
    case downloadFile(String)
    case requestFile(String)
}

extension GitHub: RemoteServiceType, AccessTokenAuthorizable {
    var accessTokenType: AccessTokenType {
        return .bearer
    }

    var baseURL: URL {
        return URL(string: "https://api.github.com")!
    }
    var path: String {
        switch self {
        case .zen:
            return "/zen"
        case .userProfile(let name):
            return "/users/\(name.urlEscaped)"
        case .downloadFile(let filename), .requestFile(let filename):
            return "/users/content/\(filename)"
        }
    }

    var method: HTTPMethod {
        return .get
    }

    var requestType: RequestType {
        switch self {
        case .zen, .userProfile, .requestFile:
            return .plain
        case .downloadFile:
            return .download(copyFile)
        }
    }

    var testData: Data {
        switch self {
        case .zen:
            return "Half measures are as bad as nothing at all.".data(using: String.Encoding.utf8)!
        case .userProfile(let name):
            return "{\"login\": \"\(name)\", \"id\": 100}".data(using: String.Encoding.utf8)!
        case .downloadFile, .requestFile:
            return Data(count: 5000)
        }
    }

    var validation: RequestValidation {
        return .successAndRedirectCodes
    }

    var headers: [String: String]? {
        return nil
    }
}

extension GitHub: Equatable {
    static func == (lhs: GitHub, rhs: GitHub) -> Bool {
        switch (lhs, rhs) {
        case (.zen, .zen):
            return true
        case let (.userProfile(username1), .userProfile(username2)):
            return username1 == username2
        default:
            return false
        }
    }
}

private let copyFile: DownloadCompletionLambda = { temporaryURL, response in
    guard let temporaryURL = temporaryURL, let response = response else {
        return
    }
    let directories = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    var path: URL?
    if !directories.isEmpty {
        path = directories.first!
        path?.appendPathComponent("logo.png")
    }
    if let path = path {
        try? FileManager.default.moveItem(at: temporaryURL, to: path)
    }
}

enum GitHubBasic {
    case zen
}

extension GitHubBasic: RemoteServiceType, AccessTokenAuthorizable {
    var accessTokenType: AccessTokenType {
        return .basic
    }

    var baseURL: URL {
        return URL(string: "https://api.github.com")!
    }
    var path: String {
        switch self {
        case .zen:
            return "/zen"
        }
    }

    var method: HTTPMethod {
        return .get
    }

    var requestType: RequestType {
        return .plain
    }

    var testData: Data {
        switch self {
        case .zen:
            return "Half measures are as bad as nothing at all.".data(using: String.Encoding.utf8)!
        }
    }

    var validation: RequestValidation {
        return .successAndRedirectCodes
    }

    var headers: [String: String]? {
        return nil
    }
}

enum GitHubCustom {
    case zen
}

extension GitHubCustom: RemoteServiceType, AccessTokenAuthorizable {
    var accessTokenType: AccessTokenType {
        return .custom("FakeAuth")
    }

    var baseURL: URL {
        return URL(string: "https://api.github.com")!
    }
    var path: String {
        switch self {
        case .zen:
            return "/zen"
        }
    }

    var method: HTTPMethod {
        return .get
    }

    var requestType: RequestType {
        return .plain
    }

    var testData: Data {
        switch self {
        case .zen:
            return "Half measures are as bad as nothing at all.".data(using: String.Encoding.utf8)!
        }
    }

    var validation: RequestValidation {
        return .successAndRedirectCodes
    }

    var headers: [String: String]? {
        return nil
    }
}

enum GitHubNone {
    case zen
}

extension GitHubNone: RemoteServiceType, AccessTokenAuthorizable {
    var accessTokenType: AccessTokenType {
        return .none
    }

    var baseURL: URL {
        return URL(string: "https://api.github.com")!
    }
    var path: String {
        switch self {
        case .zen:
            return "/zen"
        }
    }

    var method: HTTPMethod {
        return .get
    }

    var requestType: RequestType {
        return .plain
    }

    var testData: Data {
        switch self {
        case .zen:
            return "Half measures are as bad as nothing at all.".data(using: String.Encoding.utf8)!
        }
    }

    var validation: RequestValidation {
        return .successAndRedirectCodes
    }

    var headers: [String: String]? {
        return nil
    }
}

enum HTTPBin: RemoteServiceType {
    case basicAuth
    case post

    var baseURL: URL { return URL(string: "http://httpbin.org")! }
    var path: String {
        switch self {
        case .basicAuth:
            return "/basic-auth/user/passwd"
        case .post:
            return "/post"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .basicAuth:
            return .get
        case .post:
            return .post
        }
    }

    var requestType: RequestType {
        switch self {
        case .basicAuth, .post:
            return .parameters(parameters: [:], encoding: URLEncoding.default)
        }
    }

    var testData: Data {
        switch self {
        case .basicAuth:
            return "{\"authenticated\": true, \"user\": \"user\"}".data(using: String.Encoding.utf8)!
        case .post:
            return "{\"args\": {}, \"data\": \"\", \"files\": {}, \"form\": {}, \"headers\": { \"Connection\": \"close\", \"Content-Length\": \"0\", \"Host\": \"httpbin.org\" },  \"json\": null, \"origin\": \"198.168.1.1\", \"url\": \"https://httpbin.org/post\"}".data(using: String.Encoding.utf8)!
        }
    }

    var headers: [String: String]? {
        return nil
    }

    var validation: RequestValidation {
        switch self {
        default:
            return .none
        }
    }
}

// MARK: - String Helpers

extension String {
    var urlEscaped: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}

struct Issue: Codable {
    let title: String
    let createdAt: Date
    let rating: Float?

    enum CodingKeys: String, CodingKey {
        case title
        case createdAt
        case rating
    }
}

struct OptionalIssue: Codable {
    let title: String?
    let createdAt: Date?
}
