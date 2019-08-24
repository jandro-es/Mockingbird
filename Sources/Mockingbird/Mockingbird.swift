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

// MARK: - Public Typealias

public typealias HTTPHeaders = [String: String]
public typealias CompletionLambda = (_ result: Result<Response, MockingbirdError>) -> Void
public typealias DownloadCompletionLambda = (_ temporaryURL: URL?, _ response: HTTPURLResponse?) -> Void

// MARK: - Internal Typealias

internal typealias RequestCompletionHandler = (Data?, URLResponse?, Swift.Error?) -> Void
internal typealias DownloadRequestCompletionHandler = (URL?, URLResponse?, Swift.Error?) -> Void

/// Protocol defining an object of type `Mockingbird`
public protocol MockingbirdType: AnyObject {
    associatedtype RemoteService: RemoteServiceType

    /// Default method to create an actual *request*. It needs a `RemoteServiceType`, and optional
    /// `DispatchQueue` and a completion lambda. It returns a `RequestOperationType` that can be
    /// cancelled
    ///
    /// - Parameters:
    ///   - endpoint: The `RemoteServiceType` that we want to create a request from
    ///   - queue: Optional `DispatchQueue` in which the result function will be executed. If not present it defaults to `main`
    ///   - completion: A `CompletionLambda` to be executed when finished
    /// - Returns: A `RequestOperationType` that can be used to cancel the request
    @discardableResult func request(_ endpoint: RemoteService, queue: DispatchQueue?, completion: @escaping CompletionLambda) -> RequestOperationType
}

/// Mockingbird implementation
open class Mockingbird<RemoteService: RemoteServiceType>: MockingbirdType {

    /// Defines the possible behaviours for stubbing the request
    ///
    /// - never: Never stub
    /// - immediate: Stub with inmediate response
    /// - delayed: Stub delaying the response the specified ammount of seconds
    public enum StubBehavior {
        case never, immediate, delayed(seconds: TimeInterval)
    }

    /// Typealias for a function that transforms an endpoint from `RemoteService` to a `Request` object
    public typealias EndpointToRequestLambda = (RemoteService) -> Request

    /// Typealias for a function that gets a `Result` object with an `URLRequest` and a `MockingbirdError`
    public typealias RequestResultLambda = (Result<URLRequest, MockingbirdError>) -> Void

    /// Typealias for a function that receives a `Request` object and a `RequestResultLambda`
    public typealias RequestLambda = (Request, @escaping RequestResultLambda) -> Void

    /// Typelias for a function that receives an endpoint from a `RemoteService` and
    /// returns the desired `StubBehavior`
    public typealias StubLambda = (RemoteService) -> StubBehavior

    /// Function that transforms an endpoint from a `RemoteService` into a `Request` object
    public let endpointToRequestLambda: EndpointToRequestLambda

    /// Function that receives a `Request` object and a `RequestResultLambda` and decides which request
    /// to execute
    public let requestLambda: RequestLambda

    /// Function that receives an endpoint from a `RemoteService` and returns the desired `StubBehavior`
    public let stubLambda: StubLambda

    /// Stores the `URLSessionConfiguration` for this instance of `Mockingbird`
    public let sessionConfiguration: URLSessionConfiguration

    /// Stores the `URLSession` for this instance of `Mockingbird`
    public let session: URLSession

    /// Collection of `MiddlewareType` instances to hook into the lifecycle
    public let middleware: [MiddlewareType]

    /// Stores if `Mockingbird` should track the requests in progress or not
    public let trackInProgress: Bool

    /// Collection of in progress `Requests`, it stores them as a dictionary of
    /// `Request` and `CompletionLambda`
    open internal(set) var inProgressRequests: [Request: [CompletionLambda]] = [:]

    /// The `DispatchQueue` to use for execution the `CompletionLambda`
    let queue: DispatchQueue?

    /// Initialises an instance of `Mockingbird` for the generic `RemoteServiceType`
    /// with the given values and a series of defaults.
    ///
    /// - Parameters:
    ///   - endpointToRequestLambda: The function used to transform an endpoint from `RemoteService` to a `Request` object,
    ///  `Mockingbird.defaultRequestMapping` by default
    ///   - requestLambda: The function used to decide which request to perform from a `Request` object and a `RequestResultLambda`,
    ///  `Mockingbird.defaultRequestMapping` by default
    ///   - stubLambda: The function that decides the stubbing behaviour, `Mockingbird.neverStub` by default
    ///   - queue: The `DispatchQueue` to use for execution of the `CompletionLambda`, nil (main) by default
    ///   - sessionConfiguration: The `URLSessionConfiguration` to use, `default` by default
    ///   - sessionTaskDelegate: The object to act as `URLSessionTaskDelegate`, nil by default
    ///   - middleware: A collection of `MiddlewareType` to hook into the lifecycle, empty by default
    ///   - trackInProgress: If the requests in progress should be tracked or not, false by default
    public init(endpointToRequestLambda: @escaping EndpointToRequestLambda = Mockingbird.defaultRequestMapping,
                requestLambda: @escaping RequestLambda = Mockingbird.defaultRequestMapping,
                stubLambda: @escaping StubLambda = Mockingbird.neverStub,
                queue: DispatchQueue? = nil,
                sessionConfiguration: URLSessionConfiguration = Mockingbird.defaultConfiguration(),
                sessionTaskDelegate: URLSessionTaskDelegate? = nil,
                middleware: [MiddlewareType] = [],
                trackInProgress: Bool = false) {

        self.endpointToRequestLambda = endpointToRequestLambda
        self.requestLambda = requestLambda
        self.stubLambda = stubLambda
        self.sessionConfiguration = sessionConfiguration
        self.middleware = middleware
        self.trackInProgress = trackInProgress
        self.queue = queue
        self.session = URLSession(configuration: sessionConfiguration, delegate: sessionTaskDelegate, delegateQueue: nil)
    }


    /// Returns a `Request` object from an endpoint in a `RemoteService` type
    ///
    /// - Parameter endpoint: The endpoint to transform into a `Request`
    /// - Returns: The `Request` object computed after applying the `endpointToRequestLambda` to the endpoint
    open func request(_ endpoint: RemoteService) -> Request {
        return endpointToRequestLambda(endpoint)
    }

    /// Default method to perform a request. It needs an endpoint from a `RemoteService` and a `CompletionLambda` as minimum.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint from a `RemoteService` to execute
    ///   - queue: The `DispatchQueue` to execute the `CompletionLambda` in, by default is nil
    ///   - completion: The `CompletionLambda` to execute when the process ends
    /// - Returns: A `RequestOperationType` object that can be used to cancel the active request
    @discardableResult open func request(_ endpoint: RemoteService, queue: DispatchQueue? = .none, completion: @escaping CompletionLambda) -> RequestOperationType {
        let queue = queue ?? self.queue
        return requestStandard(endpoint, queue: queue, completion: completion)
    }

    /// Function used to stub a request. Based on the input parameters and the stub behaviour it will
    /// stub the reqeust and return the stubbed response from the Stubbing function of the endpoint
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint of the `RemoteService` to stub
    ///   - urlRequest: The generated `URLRequest` to stub
    ///   - queue: The `DispatchQueue` to execute the `CompletionLambda` in
    ///   - completion: The `CompletionLambda` to execute on completion
    ///   - request: The `Request` object we want to stub
    ///   - stubBehavior: The `StubBehavior` to use
    /// - Returns: A `RequestOperation` object that can be used to cancel the active request
    @discardableResult open func stubRequest(_ endpoint: RemoteService, urlRequest: URLRequest, queue: DispatchQueue?, completion: @escaping CompletionLambda, request: Request, stubBehavior: StubBehavior) -> RequestOperation {
        let queue = queue ?? self.queue
        let requestOperation = RequestOperation { }
        let middleware = self.middleware
        middleware.forEach {
            $0.willSend(urlRequest, endpoint: endpoint)
        }
        let stub: () -> Void = stubFunction(requestOperation, for: endpoint, completion: completion, request: request, middleware: middleware, urlRequest: urlRequest)
        switch stubBehavior {
        case .immediate:
            switch queue {
            case .none:
                stub()
            case .some(let execQueue):
                execQueue.async(execute: stub)
            }
        case .delayed(let delay):
            let killTimeOffset = Int64(CDouble(delay) * CDouble(NSEC_PER_SEC))
            let killTime = DispatchTime.now() + Double(killTimeOffset) / Double(NSEC_PER_SEC)
            (queue ?? DispatchQueue.main).asyncAfter(deadline: killTime) {
                stub()
            }
        case .never:
            fatalError("Trying to stub a request when stubbing is disabled")
        }
        return requestOperation
    }

    /// Static method to map a `Foundation` `URLResponse` into a `Result<Response, MockingbirdError>` object. During the mapping it will
    /// validate the response according to the specified status codes.
    ///
    /// - Parameters:
    ///   - response: The `URLResponse` returned
    ///   - urlRequest: The original `URLRequest`
    ///   - validStatusCodes: The collection of valid status codes for validation
    ///   - data: The optional returned `Data` object
    ///   - error: Any possible returned `Swift.Error`
    /// - Returns: An object of type `Result<Response, MockingbirdError>` resulted from the mapping
    public static func mapResponseToResult(_ response: URLResponse?, urlRequest: URLRequest?, validStatusCodes: [Int], data: Data?, error: Swift.Error?) -> Result<Response, MockingbirdError> {
        switch (response, data, error) {
        case let (.some(response), data, .none):
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = MockingbirdError.network(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotParseResponse, userInfo: nil), nil)
                return .failure(error)
            }
            let response = Response(statusCode: httpResponse.statusCode, data: data ?? Data(), urlRequest: urlRequest, response: httpResponse)
            if validStatusCodes.contains(response.statusCode) {
                return .success(response)
            } else {
                let error = MockingbirdError.invalidStatusCode(response)
                return .failure(error)
            }
        case let (.some(response), _, .some(error)):
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = MockingbirdError.network(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotParseResponse, userInfo: nil), nil)
                return .failure(error)
            }
            let response = Response(statusCode: httpResponse.statusCode, data: data ?? Data(), urlRequest: urlRequest, response: httpResponse)
            let error = MockingbirdError.network(error, response)
            return .failure(error)
        case let (_, _, .some(error)):
            let error = MockingbirdError.network(error, nil)
            return .failure(error)
        default:
            let error = MockingbirdError.network(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil), nil)
            return .failure(error)
        }
    }
}

public extension Mockingbird {

    /// Method to execute a standard request from a given `RemoteService` endpoint
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint from a `RemoteService` to use
    ///   - queue: The `DispatchQueue` to execute the `CompletionLambda` in
    ///   - completion: The `CompletionLambda` to execute in completion
    /// - Returns: A `RequestOperationType` object that can be used to cancel the active request
    func requestStandard(_ endpoint: RemoteService, queue: DispatchQueue?, completion: @escaping CompletionLambda) -> RequestOperationType {
        let request = self.request(endpoint)
        let stubBehavior = self.stubLambda(endpoint)
        let requestOperation = RequestOperationWrapper()

        // Allow plugins to modify response
        let middlewareWithCompletion: CompletionLambda = { result in
            let processedResult = self.middleware.reduce(result) { $1.process($0, endpoint: endpoint) }
            completion(processedResult)
        }

        if trackInProgress {
            objc_sync_enter(self)
            var inProgressCompletionLambdas = self.inProgressRequests[request]
            inProgressCompletionLambdas?.append(middlewareWithCompletion)
            self.inProgressRequests[request] = inProgressCompletionLambdas
            objc_sync_exit(self)

            if inProgressCompletionLambdas != nil {
                return requestOperation
            } else {
                objc_sync_enter(self)
                self.inProgressRequests[request] = [middlewareWithCompletion]
                objc_sync_exit(self)
            }
        }

        let performNetworking = { (requestResult: Result<URLRequest, MockingbirdError>) in
            guard !requestOperation.isCancelled else {
                self.cancelCompletion(middlewareWithCompletion, endpoint: endpoint)
                return
            }

            var urlRequest: URLRequest!
            switch requestResult {
            case .success(let urlReq):
                urlRequest = urlReq
            case .failure(let error):
                middlewareWithCompletion(.failure(error))
                return
            }

            let preparedRequest = self.middleware.reduce(urlRequest) { $1.prepare($0, endpoint: endpoint) }

            let networkCompletion: CompletionLambda = { result in
                if self.trackInProgress {
                    self.inProgressRequests[request]?.forEach {
                        $0(result)
                    }

                    objc_sync_enter(self)
                    self.inProgressRequests.removeValue(forKey: request)
                    objc_sync_exit(self)
                } else {
                    middlewareWithCompletion(result)
                }
            }

            requestOperation.innerRequestOperation = self.performRequest(endpoint, urlRequest: preparedRequest, queue: queue, completion: networkCompletion, request: request, stubBehavior: stubBehavior)
        }
        requestLambda(request, performNetworking)
        return requestOperation
    }

    /// Cancels a `CompletionLambda`, returning an error of type `NSURLErrorCancelled` and calling the proper
    /// `MiddlewareType`
    ///
    /// - Parameters:
    ///   - completion: The `CompletionLambda` to cancel
    ///   - endpoint: The endpoint from the `RemoteService` that you want to cancel
    func cancelCompletion(_ completion: CompletionLambda, endpoint: RemoteService) {
        let error = MockingbirdError.network(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil), nil)
        for middlewareItem in middleware {
            middlewareItem.didReceive(.failure(error), endpoint: endpoint)
        }
        completion(.failure(error))
    }

    /// Private function which calls the needed discrete method based in the `RequestType`
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint from the `RemoteService` that triggered the request
    ///   - urlRequest: The generated `URLRequest`
    ///   - queue: The `DispatchQueue` to use for executing the `CompletionLambda`
    ///   - completion: The `CompletionLambda` to execute on completion
    ///   - request: The generated `Request` object
    ///   - stubBehavior: The `StubBehavior` to use
    /// - Returns: A `RequestOperationType` object that can be used to cancel the active request
    private func performRequest(_ endpoint: RemoteService, urlRequest: URLRequest, queue: DispatchQueue?, completion: @escaping CompletionLambda, request: Request, stubBehavior: StubBehavior) -> RequestOperationType {
        switch stubBehavior {
        case .never:
            switch request.requestType {
            case .plain, .data, .JSONEncodable, .customJSONEncodable, .parameters, .compositeData, .compositeParameters:
                return sendRequest(endpoint, urlRequest: urlRequest, queue: queue, completion: completion)
            case .download(let destination), .downloadParameters(_, _, let destination):
                return sendDownloadRequest(endpoint, urlRequest: urlRequest, queue: queue, destination: destination, completion: completion)
            }
        default:
            return self.stubRequest(endpoint, urlRequest: urlRequest, queue: queue, completion: completion, request: request, stubBehavior: stubBehavior)
        }
    }

    /// Method that generates and returns a stub function from the given parameters
    ///
    /// - Parameters:
    ///   - requestOperation: The `RequestOperation` that we want to stub
    ///   - endpoint: The endpoint from the `RemoteService` that we want to stub
    ///   - completion: The `CompletionLambda` to execute on completion
    ///   - request: The generated `Request` object
    ///   - middleware: The collection of `MiddlewareType` to use
    ///   - urlRequest: The generated `URLRequest`
    final func stubFunction(_ requestOperation: RequestOperation, for endpoint: RemoteService, completion: @escaping CompletionLambda, request: Request, middleware: [MiddlewareType], urlRequest: URLRequest) -> (() -> Void) {
        return {
            if requestOperation.isCancelled {
                self.cancelCompletion(completion, endpoint: endpoint)
                return
            }

            let validate = { (response: Response) -> Result<Response, MockingbirdError> in
                let validCodes = endpoint.validation.statusCodes
                guard !validCodes.isEmpty else {
                    return .success(response)
                }
                if validCodes.contains(response.statusCode) {
                    return .success(response)
                } else {
                    let error = MockingbirdError.invalidStatusCode(response)
                    return .failure(error)
                }
            }

            switch request.sampleResponse() {
            case .networkResponse(let statusCode, let data):
                let response = Response(statusCode: statusCode, data: data, urlRequest: urlRequest, response: nil)
                let result = validate(response)
                middleware.forEach {
                    $0.didReceive(result, endpoint: endpoint)
                }
                completion(result)
            case .response(let customResponse, let data):
                let response = Response(statusCode: customResponse.statusCode, data: data, urlRequest: urlRequest, response: customResponse)
                let result = validate(response)
                middleware.forEach {
                    $0.didReceive(result, endpoint: endpoint)
                }
                completion(result)
            case .networkError(let error):
                let error = MockingbirdError.network(error, nil)
                middleware.forEach {
                    $0.didReceive(.failure(error), endpoint: endpoint)
                }
                completion(.failure(error))
            }
        }
    }
}

private extension Mockingbird {

    /// Sends a request using an `URLSession.dataTask` with the given parameters
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint from the `RemoteService` that generated the request
    ///   - urlRequest: The generated `URLRequest`
    ///   - queue: The `DispatchQueue` to execute the `CompletionLambda` in
    ///   - completion: The `CompletionLambda` to execute on completion
    /// - Returns: A `RequestOperation` that can be used to cancel the actual request
    func sendRequest(_ endpoint: RemoteService, urlRequest: URLRequest, queue: DispatchQueue?, completion: @escaping CompletionLambda) -> RequestOperation {
        let validStatusCodes = endpoint.validation.statusCodes
        return startDataTask(endpoint: endpoint, urlRequest: urlRequest, validStatusCodes: validStatusCodes, queue: queue, completion: completion)
    }

    /// Sends a download request using an `URLSession.downloadTask` with the given parameters
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint from the `RemoteService` that generated the request
    ///   - urlRequest: The generated `URLRequest`
    ///   - queue: The `DispatchQueue` to execute the `CompletionLambda` in
    ///   - destination: A `DownloadCompletionLambda` used to finalise the download
    ///   - completion: The `CompletionLambda` to execute on completion
    /// - Returns: A `RequestOperation` that can be used to cancel the actual request
    func sendDownloadRequest(_ endpoint: RemoteService, urlRequest: URLRequest, queue: DispatchQueue?, destination: @escaping DownloadCompletionLambda, completion: @escaping CompletionLambda) -> RequestOperation {
        let validStatusCodes = endpoint.validation.statusCodes
        return startDownloadTask(endpoint: endpoint, urlRequest: urlRequest, validStatusCodes: validStatusCodes, queue: queue, destination: destination, completion: completion)
    }

    /// Starts an `URLSession.dataTask` with the given parameters
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint from the `RemoteService` that generated the request
    ///   - urlRequest: The generated `URLRequest`
    ///   - validStatusCodes: A collection of the valid status codes to use for validation
    ///   - queue: The `DispatchQueue` to execute the `CompletionLambda` in
    ///   - completion: The `CompletionLambda` to execute on completion
    /// - Returns: A `RequestOperation` that can be used to cancel the actual request
    func startDataTask(endpoint: RemoteService, urlRequest: URLRequest, validStatusCodes: [Int], queue: DispatchQueue?, completion: @escaping CompletionLambda) -> RequestOperation {
        middleware.forEach({
            $0.willSend(urlRequest, endpoint: endpoint)
        })
        let completionHandler: RequestCompletionHandler = { [weak self](data, response, error) in
            let result = Mockingbird.mapResponseToResult(response, urlRequest: urlRequest, validStatusCodes: validStatusCodes, data: data, error: error)
            self?.middleware.forEach {
                $0.didReceive(result, endpoint: endpoint)
            }
            // By default we use the `.main` Queue
            var calloutQueue: DispatchQueue = .main
            if let queue = queue {
                // if the actual task has an specific queue we use it
                calloutQueue = queue
            } else if let queue = self?.queue {
                // If the `Mockingbird` instance has a default queue, we use it
                calloutQueue = queue
            }
            calloutQueue.async {
                completion(result)
            }
        }
        let task = session.dataTask(with: urlRequest, completionHandler: completionHandler)
        task.resume()
        return RequestOperation(task: task)
    }

    /// Starts an `URLSession.downloadTask` with the given parameters
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint from the `RemoteService` that generated the request
    ///   - urlRequest: The generated `URLRequest`
    ///   - validStatusCodes: A collection of the valid status codes to use for validation
    ///   - queue: The `DispatchQueue` to execute the `DownloadCompletionLambda` in
    ///   - destination: The `DownloadCompletionLambda` to execute on completion
    ///   - completion: The `CompletionLambda` to execute on completion
    /// - Returns: A `RequestOperation` that can be used to cancel the actual request
    func startDownloadTask(endpoint: RemoteService, urlRequest: URLRequest, validStatusCodes: [Int], queue: DispatchQueue?, destination: @escaping DownloadCompletionLambda, completion: @escaping CompletionLambda) -> RequestOperation {
        middleware.forEach({
            $0.willSend(urlRequest, endpoint: endpoint)
        })
        let completionHandler: DownloadRequestCompletionHandler = { [weak self](url, response, error) in
            let result = Mockingbird.mapResponseToResult(response, urlRequest: urlRequest, validStatusCodes: validStatusCodes, data: Data(), error: error)
            self?.middleware.forEach {
                $0.didReceive(result, endpoint: endpoint)
            }
            // By default we use the `.main` Queue
            var calloutQueue: DispatchQueue = .main
            if let queue = queue {
                // if the actual task has an specific queue we use it
                calloutQueue = queue
            } else if let queue = self?.queue {
                // If the `Mockingbird` instance has a default queue, we use it
                calloutQueue = queue
            }
            calloutQueue.async {
                destination(url, response as? HTTPURLResponse)
                completion(result)
            }
        }
        let task = session.downloadTask(with: urlRequest, completionHandler: completionHandler)
        task.resume()
        return RequestOperation(task: task)
    }
}

public extension Mockingbird {

    /// Class method to set `StubBehavior` to `.never`
    ///
    /// - Returns: A `Mockingbird.StubBehavior`
    final class func neverStub(_: RemoteServiceType) -> Mockingbird.StubBehavior {
        return .never
    }

    /// Class method to set the `StubBehavior` to `.immediate`
    ///
    /// - Returns: A `Mockingbird.StubBehavior`
    final class func immediatelyStub(_: RemoteServiceType) -> Mockingbird.StubBehavior {
        return .immediate
    }

    /// Class method to set the `StubBehavior` to `.delayed` with the given ammount of seconds
    ///
    /// - Parameter seconds: The ammount of seconds to delay the response
    /// - Returns: A `Mockingbird.StubBehavior`
    final class func delayedStub(_ seconds: TimeInterval) -> (RemoteServiceType) -> Mockingbird.StubBehavior {
        return { _ in
            return .delayed(seconds: seconds)
        }
    }
}
