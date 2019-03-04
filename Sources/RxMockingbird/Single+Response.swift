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

extension PrimitiveSequence where TraitType == SingleTrait, E == Response {

    /// Rx operator that filters the `Response` if the status code is not contained
    /// in the given ones. Generates errors when impossible to satisfy.
    ///
    /// - Parameter statusCodes: The collection of status code to validate against
    /// - Returns: An observable of type `Single<Response>`
    public func filter<R: RangeExpression>(statusCodes: R) -> Single<E> where R.Bound == Int {
        return flatMap {
            Single.just( try $0.filter(statusCodes: statusCodes ))
        }
    }

    /// Rx operator that filters the `Response` if the status code is not equal
    /// than the given one. Generates errors when impossible to satisfy.
    ///
    /// - Parameter statusCode: The status code to validate against
    /// - Returns: An observable of type `Single<Response>`
    public func filter(statusCode: Int) -> Single<E> {
        return flatMap {
            Single.just( try $0.filter(statusCode: statusCode) )
        }
    }

    /// Rx operator that filters the `Response` if the status code is not in the
    /// standard success ones (200,...,299). Generates errors when impossible to satisfy.
    ///
    /// - Returns: An observable of type `Single<Response>`
    public func filterSuccessfulStatusCodes() -> Single<E> {
        return flatMap {
            Single.just( try $0.filterSuccessfulStatusCodes() )
        }
    }

    /// Rx operator that filters the `Response` if the status code is not in the
    /// standard success or redirect ones (200,...,399). Generates errors when impossible to satisfy.
    ///
    /// - Returns: An observable of type `Single<Response>`
    public func filterSuccessfulStatusAndRedirectCodes() -> Single<E> {
        return flatMap {
            Single.just( try $0.filterSuccessfulStatusAndRedirectCodes() )
        }
    }

    /// Rx operator that maps the received `Data` object into a JSON object. Returning the mapping
    /// error if it fails.
    ///
    /// - Parameter failsOnEmptyData: If it should fail when the `Data` object is empty or not
    /// - Returns: An observable of type `Single<Any>
    public func mapJSON(failsOnEmptyData: Bool = true) -> Single<Any> {
        return flatMap {
            Single.just( try $0.mapJSON(failsOnEmptyData: failsOnEmptyData) )
        }
    }

    /// Rx operator to map the received `Data` object, with an optional `Keypath` into a `String`. If it fails
    /// it returns the mapping errors.
    ///
    /// - Parameter keyPath: The optional `Keypath` to start the mapping
    /// - Returns: An obserbable of type `Single<String>`
    public func mapString(at keyPath: String? = nil) -> Single<String> {
        return flatMap {
            Single.just( try $0.mapString(at: keyPath) )
        }
    }

    /// Rx operator to map the received `Data` object into a `Decodable` compatible object. If the mapping
    /// fails it returns the mapping errors.
    ///
    /// - Parameters:
    ///   - type: The type of a `Decodable` compatible type to map the response into it
    ///   - keyPath: The optional `Keypath` to start the mapping
    ///   - decoder: An optional `JSONDecoder`, it uses `JSONDecoder()` as default
    ///   - failsOnEmptyData: If it should fail or not when the `Data` object is empty
    /// - Returns: An observable of type `Single<D>` with `D` being the `Decodable` compatible type
    public func map<D: Decodable>(_ type: D.Type, at keyPath: String? = nil, using decoder: JSONDecoder = JSONDecoder(), failsOnEmptyData: Bool = true) -> Single<D> {
        return flatMap {
            Single.just( try $0.map(type, at: keyPath, using: decoder, failsOnEmptyData: failsOnEmptyData) )
        }
    }
}
