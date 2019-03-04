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

import os.log

@available(iOS 10.0, OSX 10.12, *)
extension OSLog {
    
    /// Defines the subsystem the framework will use for logging
    private static var subsystem = "com.filtercode.mockingbird"

    // MARK: - Categories

    /// RequestOperation category
    static let requestOperation = OSLog(subsystem: subsystem, category: "request_operation")

    /// Endpoints category
    static let request = OSLog(subsystem: subsystem, category: "request")

    /// Responses category
    static let response = OSLog(subsystem: subsystem, category: "response")

    /// Middleware category
    static let middleware = OSLog(subsystem: subsystem, category: "middleware")
}
