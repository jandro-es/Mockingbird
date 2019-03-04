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
import RxSwift
#if !COCOAPODS
import Mockingbird
#endif

extension Mockingbird: ReactiveCompatible { }

public extension Reactive where Base: MockingbirdType {

    /// Rx extension method that wraps a request into a an `Single` observable
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint of the `RemoteService`
    ///   - queue: The `DispatchQueue` to use
    /// - Returns: A singel observable of type `Single<Response>`
    public func request(_ endpoint: Base.RemoteService, queue: DispatchQueue? = nil) -> Single<Response> {
        return Single.create { [weak base] single in
            let requestOperation = base?.request(endpoint, queue: queue) { result in
                switch result {
                case let .success(response):
                    single(.success(response))
                case let .failure(error):
                    single(.error(error))
                }
            }
            return Disposables.create {
                requestOperation?.cancel()
            }
        }
    }
}
