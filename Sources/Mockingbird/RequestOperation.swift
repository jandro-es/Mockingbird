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

/// Defines the abstract type that is returned
/// when a `Mockingbird` operation has been defined
public protocol RequestOperationType {

    /// Stores if the operation has been cancelled or not
    var isCancelled: Bool { get }

    /// Cancels the HTTP request contained
    /// in the `RequestOperation`
    func cancel()
}

/// Type that is returned when a `Mockingbird` operation has been defined
public final class RequestOperation: RequestOperationType, CustomDebugStringConvertible {

    /// Holds the cancellation lambda, to be executed
    /// when the `cancel` method is called
    let cancelLambda: () -> Void

    /// Hold the `URLSessionTask` generated for the request. It'll
    /// be the recipient of the cancel lambda if called.
    let task: URLSessionTask?

    /// Protocol `RequestOperationType` compliance which holds
    /// if the operation was cancelled or not.
    public fileprivate(set) var isCancelled = false

    /// Private lock to guarantee the not two threads can cancel or alter
    // state at the same time.
    fileprivate var lock: DispatchSemaphore = DispatchSemaphore(value: 1)

    // MARK: - Initializers

    /// Initializes a `RequestOperation` instance with the passed
    /// escaping lambda as the lambda to execute when cancelling.
    /// The `URLSessionTask` is defined as nil.
    ///
    /// - Parameter lambda: The escaping lambda to execute
    public init(lambda: @escaping () -> Void) {
        self.cancelLambda = lambda
        self.task = nil
    }

    /// Initializes a `RequestOperation` instance with the
    /// given `URLSessionTask`. It creates a cancellation
    /// lambda that cancels said task.
    ///
    /// - Parameter task: The `URLSessionTask` to store
    init(task: URLSessionTask) {
        self.task = task
        self.cancelLambda = {
            switch task.state {
            case .running, .suspended:
                if #available(iOS 10, OSX 10.12, *) {
                    os_log("Cancelling URLSessionTask %@", log: OSLog.requestOperation, type: .debug, task.debugDescription)
                }
                task.cancel()
            default:
                if #available(iOS 10, OSX 10.12, *) {
                    os_log("URLSessionTask %@ already cancelled, not possible to cancel it again", log: OSLog.requestOperation, type: .debug, task.debugDescription)
                }
            }
        }
    }

    /// Protocol `RequestOperationType` compliance, it cancels in a
    /// `thread safe` manner the `URLSessionTask` contained. It updates
    /// the value of the `isCancelled` property and executes the `cancelLambda`
    /// function.
    public func cancel() {
        _ = lock.wait(timeout: DispatchTime.distantFuture)
        defer {
            lock.signal()
        }
        guard !isCancelled else {
            return
        }
        isCancelled = true
        cancelLambda()
    }

    /// Protocol `CustomDebugStringConvertible` compliance
    public var debugDescription: String {
        guard let task = self.task else {
            return "No task"
        }
        return task.debugDescription
    }
}

// MARK: - Internal classes

/// Internal Wrapper for `RequestOperationType` which allows to abstract the
/// actual `URLSessionTask` operations until they are actually created lazily.
internal class RequestOperationWrapper: RequestOperationType {

    internal var innerRequestOperation: RequestOperationType = SimpleRequestOperation()

    var isCancelled: Bool {
        return innerRequestOperation.isCancelled
    }

    internal func cancel() {
        innerRequestOperation.cancel()
    }
}

/// Internal `Simple` `RequestOperation` that allows the system
/// to postpone and abstract the actual creation of the `URLSessionTask`
internal class SimpleRequestOperation: RequestOperationType {

    var isCancelled = false

    func cancel() {
        isCancelled = true
    }
}
