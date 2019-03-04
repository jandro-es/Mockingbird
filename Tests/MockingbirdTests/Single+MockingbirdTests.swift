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

import XCTest
import RxSwift
@testable import Mockingbird
@testable import RxMockingbird

final class Single_MockingbirdTests: XCTestCase {

    let formatter = DateFormatter()
    let decoder = JSONDecoder()

    var json: [String: Any] = [
        "title": "Hello, World",
        "createdAt": "1995-01-14T12:34:56"
    ]
    
    override func setUp() {
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        decoder.dateDecodingStrategy = .formatted(formatter)
    }
    
    override func tearDown() { }
    
    func test_filter_statuscodes_range_closed_range_upperbound() {
        let data = Data()
        let single = Response(statusCode: 10, data: data).asSingle()
        var errored = false
        _ = single.filter(statusCodes: 0...9).subscribe { event in
            switch event {
            case .success(_):
                XCTFail("The status code is not valid, it should have failed")
            case .error:
                errored = true
            }
        }
        XCTAssertTrue(errored)
    }
    
    func test_filter_statuscodes_range_closed_lowerbound() {
        let data = Data()
        let single = Response(statusCode: -1, data: data).asSingle()
        var errored = false
        _ = single.filter(statusCodes: 0...9).subscribe { event in
            switch event {
            case .success(_):
                XCTFail("The status code is not valid, it should have failed")
            case .error:
                errored = true
            }
        }
        XCTAssertTrue(errored)
    }
    
    func test_filter_statuscodes_range_upperbound() {
        let data = Data()
        let single = Response(statusCode: 10, data: data).asSingle()
        var errored = false
        _ = single.filter(statusCodes: 0..<10).subscribe { event in
            switch event {
            case .success(_):
                XCTFail("The status code is not valid, it should have failed")
            case .error:
                errored = true
            }
        }
        XCTAssertTrue(errored)
    }
    
    func test_filter_statuscodes_lowerbound() {
        let data = Data()
        let single = Response(statusCode: -1, data: data).asSingle()
        var errored = false
        _ = single.filter(statusCodes: 0..<10).subscribe { event in
            switch event {
            case .success(_):
                XCTFail("The status code is not valid, it should have failed")
            case .error:
                errored = true
            }
        }
        XCTAssertTrue(errored)
    }
    
    func test_filter_non_success_statuscodes() {
        let data = Data()
        let single = Response(statusCode: 404, data: data).asSingle()
        var errored = false
        _ = single.filterSuccessfulStatusCodes().subscribe { event in
            switch event {
            case .success(_):
                XCTFail("The status code is not valid, it should have failed")
            case .error:
                errored = true
            }
        }
        XCTAssertTrue(errored)
    }
    
    func test_accepts_success_statuscodes() {
        let data = Data()
        let single = Response(statusCode: 200, data: data).asSingle()
        var passed = false
        _ = single.filterSuccessfulStatusCodes().subscribe(onSuccess: { _ in
            passed = true
        })
        XCTAssertTrue(passed)
    }

    func test_filters_failures_and_redirects() {
        let data = Data()
        let single = Response(statusCode: 404, data: data).asSingle()
        var errored = false
        _ = single.filterSuccessfulStatusAndRedirectCodes().subscribe { event in
            switch event {
            case .success(_):
                XCTFail("The status code is not valid, it should have failed")
            case .error:
                errored = true
            }
        }
        XCTAssertTrue(errored)
    }

    func test_accepts_success_even_when_filtering_redirects() {
        let data = Data()
        let single = Response(statusCode: 200, data: data).asSingle()
        var passed = false
        _ = single.filterSuccessfulStatusAndRedirectCodes().subscribe(onSuccess: { _ in
            passed = true
        })
        XCTAssertTrue(passed)
    }

    func test_accepts_redirects() {
        let data = Data()
        let single = Response(statusCode: 304, data: data).asSingle()
        var passed = false
        _ = single.filterSuccessfulStatusAndRedirectCodes().subscribe(onSuccess: { _ in
            passed = true
        })
        XCTAssertTrue(passed)
    }

    func test_accepts_specific_statuscodes() {
        let data = Data()
        let single = Response(statusCode: 42, data: data).asSingle()
        var passed = false
        _ = single.filter(statusCode: 42).subscribe(onSuccess: { _ in
            passed = true
        })
        XCTAssertTrue(passed)
    }

    func test_filters_specific_statuscodes() {
        let data = Data()
        let single = Response(statusCode: 43, data: data).asSingle()
        var errored = false
        _ = single.filter(statusCode: 42).subscribe { event in
            switch event {
            case .success(_):
                XCTFail("The status code is not valid, it should have failed")
            case .error:
                errored = true
            }
        }
        XCTAssertTrue(errored)
    }

    func test_maps_correct_json() {
        let json = ["name": "Darth Vader", "job": "Sith"]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            fatalError("Failed creating Data from JSON dictionary")
        }
        let single = Response(statusCode: 200, data: data).asSingle()
        var receivedJSON: [String: String]?
        _ = single.mapJSON().subscribe(onSuccess: { json in
            if let json = json as? [String: String] {
                receivedJSON = json
            }
        })
        XCTAssertEqual(receivedJSON?["name"], "Darth Vader")
        XCTAssertEqual(receivedJSON?["job"], "Sith")
    }

    func test_returns_foundation_error_for_invalid_json() {
        let json = "{ \"name\": \"Darth }"
        guard let data = json.data(using: .utf8) else {
            fatalError("Failed creating Data from JSON String")
        }
        let single = Response(statusCode: 200, data: data).asSingle()
        var receivedError: MockingbirdError?
        _ = single.mapJSON().subscribe { event in
            switch event {
            case .success:
                XCTFail("Invalid JSON, should fail")
            case .error(let error):
                receivedError = error as? MockingbirdError
            }
        }
        XCTAssertNotNil(receivedError)
        switch receivedError {
        case .some(.jsonMapping):
            break
        default:
            XCTFail("Wrong type of error")
        }
    }

    func test_maps_data_to_string() {
        let string = "En un lugar de la mancha cuyo nombre no quiero acordarme"
        guard let data = string.data(using: .utf8) else {
            fatalError("Failed creating Data from String")
        }
        let single = Response(statusCode: 200, data: data).asSingle()
        var receivedString: String?
        _ = single.mapString().subscribe(onSuccess: { string in
            receivedString = string
        })
        XCTAssertEqual(receivedString, string)
    }

    func test_maps_data_in_keypath_to_string() {
        let string = "En un lugar de la mancha cuyo nombre no quiero acordarme"
        let json = ["quixote_start": string]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            fatalError("Failed creating Data from JSON dictionary")
        }
        let single = Response(statusCode: 200, data: data).asSingle()
        var receivedString: String?
        _ = single.mapString(at: "quixote_start").subscribe(onSuccess: { string in
            receivedString = string
        })
        XCTAssertEqual(receivedString, string)
    }

    func test_map_string_ignores_invalid_data() {
        let data = Data(bytes: [0x11FFFF] as [UInt32], count: 1)
        let single = Response(statusCode: 200, data: data).asSingle()
        var receivedError: MockingbirdError?
        _ = single.mapString().subscribe { event in
            switch event {
            case .success:
                XCTFail("Should fail as the data is over the range of UTF8")
            case .error(let error):
                receivedError = error as? MockingbirdError
            }
        }
        XCTAssertNotNil(receivedError)
        let expectedError = MockingbirdError.stringMapping(Response(statusCode: 200, data: Data(), response: nil))
        XCTAssertEqual(receivedError?.localizedDescription, expectedError.localizedDescription)
    }

    func test_maps_json_to_decodable() {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            preconditionFailure("Failed creating Data from JSON dictionary")
        }
        let single = Response(statusCode: 200, data: data).asSingle()
        var receivedObject: Issue?
        _ = single.map(Issue.self, using: decoder).subscribe(onSuccess: { issue in
            receivedObject = issue
        })
        XCTAssertNotNil(receivedObject)
        XCTAssertEqual(receivedObject?.title, "Hello, World")
        XCTAssertEqual(receivedObject?.createdAt, formatter.date(from: "1995-01-14T12:34:56"))
    }

    func test_maps_collection_of_decodable_json() {
        let jsonArray = [json, json, json]
        guard let data = try? JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted) else {
            preconditionFailure("Failed creating Data from JSON dictionary")
        }
        let single = Response(statusCode: 200, data: data).asSingle()
        var receivedObjects: [Issue]?
        _ = single.map([Issue].self, using: decoder).subscribe(onSuccess: { issues in
            receivedObjects = issues
        })
        XCTAssertNotNil(receivedObjects)
        XCTAssertEqual(receivedObjects?.count, 3)
        XCTAssertEqual(receivedObjects?.compactMap({ $0.title }), [json["title"] as! String, json["title"] as! String, json["title"] as! String])
    }

    func test_maps_empty_data_to_optional_decodable() {
        let single = Response(statusCode: 200, data: Data()).asSingle()
        var receivedObject: OptionalIssue?
        _ = single.map(OptionalIssue.self, using: decoder, failsOnEmptyData: false).subscribe(onSuccess: { object in
            receivedObject = object
        })
        XCTAssertNotNil(receivedObject)
        XCTAssertNil(receivedObject?.title)
        XCTAssertNil(receivedObject?.createdAt)
    }

    func test_maps_empty_data_to_collection_of_optionals() {
        let single = Response(statusCode: 200, data: Data()).asSingle()
        var receivedObjects: [OptionalIssue]?
        _ = single.map([OptionalIssue].self, using: decoder, failsOnEmptyData: false).subscribe(onSuccess: { object in
            receivedObjects = object
        })
        XCTAssertNotNil(receivedObjects)
        XCTAssertEqual(receivedObjects?.count, 1)
        XCTAssertNil(receivedObjects?.first?.title)
        XCTAssertNil(receivedObjects?.first?.createdAt)
    }

    func test_maps_to_decodable_with_keypath() {
        let jsonObject: [String: Any] = ["issue": json]
        guard let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
            preconditionFailure("Failed creating Data from JSON dictionary")
        }
        let single = Response(statusCode: 200, data: data).asSingle()
        var receivedObject: Issue?
        _ = single.map(Issue.self, at: "issue", using: decoder).subscribe(onSuccess: { object in
            receivedObject = object
        })
        XCTAssertNotNil(receivedObject)
        XCTAssertEqual(receivedObject?.title, "Hello, World")
        XCTAssertEqual(receivedObject?.createdAt, formatter.date(from: "1995-01-14T12:34:56"))
    }

    func test_maps_to_decodable_collection_with_keypath() {
        let jsonObject: [String: Any] = ["issues": [json, json]]
        guard let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
            preconditionFailure("Failed creating Data from JSON dictionary")
        }
        let single = Response(statusCode: 200, data: data).asSingle()
        var receivedObjects: [Issue]?
        _ = single.map([Issue].self, at: "issues", using: decoder).subscribe(onSuccess: { object in
            receivedObjects = object
        })
        XCTAssertNotNil(receivedObjects)
        XCTAssertEqual(receivedObjects?.count, 2)
        XCTAssertEqual(receivedObjects?.compactMap({ $0.title }), [json["title"] as! String, json["title"] as! String])
    }

    func test_maps_empty_data_to_optional_decodable_with_keypath() {
        let single = Response(statusCode: 200, data: Data()).asSingle()
        var receivedObject: OptionalIssue?
        _ = single.map(OptionalIssue.self, at: "issue", using: decoder, failsOnEmptyData: false).subscribe(onSuccess: { object in
            receivedObject = object
        })
        XCTAssertNotNil(receivedObject)
        XCTAssertNil(receivedObject?.title)
        XCTAssertNil(receivedObject?.createdAt)
    }

    func test_maps_empty_data_to_collection_of_optional_decodable_with_keypath() {
        let single = Response(statusCode: 200, data: Data()).asSingle()
        var receivedObjects: [OptionalIssue]?
        _ = single.map([OptionalIssue].self, at: "issue", using: decoder, failsOnEmptyData: false).subscribe(onSuccess: { object in
            receivedObjects = object
        })
        XCTAssertNotNil(receivedObjects)
        XCTAssertEqual(receivedObjects?.count, 1)
        XCTAssertNil(receivedObjects?.first?.title)
        XCTAssertNil(receivedObjects?.first?.createdAt)
    }

    func test_maps_into_int() {
        let json: [String: Any] = ["count": 1]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            preconditionFailure("Failed creating Data from JSON dictionary")
        }
        let observable = Response(statusCode: 200, data: data).asSingle()
        var count: Int?
        _ = observable.map(Int.self, at: "count", using: decoder).subscribe(onSuccess: { value in
            count = value
        })
        XCTAssertEqual(count, 1)
    }

    func test_maps_into_bool() {
        let json: [String: Any] = ["isNew": true]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            preconditionFailure("Failed creating Data from JSON dictionary")
        }
        let observable = Response(statusCode: 200, data: data).asSingle()
        var isNew: Bool?
        _ = observable.map(Bool.self, at: "isNew", using: decoder).subscribe(onSuccess: { value in
            isNew = value
        })
        XCTAssertTrue(isNew ?? false)
    }

    func test_maps_into_string() {
        let json: [String: Any] = ["description": "Lorem ipsum dolore et sumun"]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            preconditionFailure("Failed creating Data from JSON dictionary")
        }
        let observable = Response(statusCode: 200, data: data).asSingle()
        var description: String?
        _ = observable.map(String.self, at: "description", using: decoder).subscribe(onSuccess: { value in
            description = value
        })
        XCTAssertEqual(description, "Lorem ipsum dolore et sumun")
    }

    func test_maps_string_into_url() {
        let json: [String: Any] = ["url": "http://www.test.com/test"]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            preconditionFailure("Failed creating Data from JSON dictionary")
        }
        let observable = Response(statusCode: 200, data: data).asSingle()
        var url: URL?
        _ = observable.map(URL.self, at: "url", using: decoder).subscribe(onSuccess: { value in
            url = value
        })
        XCTAssertEqual(url, URL(string: "http://www.test.com/test"))
    }

    func test_map_should_fail_from_into_to_bool() {
        let json: [String: Any] = ["isNew": 1]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            preconditionFailure("Failed creating Data from JSON dictionary")
        }
        let observable = Response(statusCode: 200, data: data).asSingle()
        var isNew: Bool?
        _ = observable.map(Bool.self, at: "isNew", using: decoder).subscribe(onSuccess: { value in
            isNew = value
        })
        XCTAssertNil(isNew)
    }

    func test_map_should_fail_string_into_int() {
        let json: [String: Any] = ["test": "123"]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            preconditionFailure("Failed creating Data from JSON dictionary")
        }
        let observable = Response(statusCode: 200, data: data).asSingle()
        var test: Int?
        _ = observable.map(Int.self, at: "test", using: decoder).subscribe(onSuccess: { value in
            test = value
        })
        XCTAssertNil(test)
    }

    func test_map_string_collection_into_string_should_fail() {
        let json: [String: Any] = ["test": ["123", "456"]]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            preconditionFailure("Failed creating Data from JSON dictionary")
        }
        let observable = Response(statusCode: 200, data: data).asSingle()
        var test: String?
        _ = observable.map(String.self, at: "test", using: decoder).subscribe(onSuccess: { value in
            test = value
        })
        XCTAssertNil(test)
    }

    func test_map_collection_string_into_string_should_fail() {
        let json: [String: Any] = ["test": "123"]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            preconditionFailure("Failed creating Data from JSON dictionary")
        }
        let observable = Response(statusCode: 200, data: data).asSingle()
        var test: [String]?
        _ = observable.map([String].self, at: "test", using: decoder).subscribe(onSuccess: { value in
            test = value
        })
        XCTAssertNil(test)
    }

    func test_ignores_invalid_data() {
        json["createdAt"] = "This is an invalid date string"
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            preconditionFailure("Failed creating Data from JSON dictionary")
        }
        let single = Response(statusCode: 200, data: data).asSingle()
        var receivedError: MockingbirdError?
        _ = single.map(Issue.self, using: decoder).subscribe { event in
            switch event {
            case .success:
                XCTFail("It should fail")
            case .error(let error):
                receivedError = error as? MockingbirdError
            }
        }
        XCTAssertNotNil(receivedError)
        if case let MockingbirdError.decodableMapping(error, _) = receivedError! {
            XCTAssertTrue(error is DecodingError)
        } else {
            XCTFail("Wrong type of error received")
        }
    }
}

extension Single_MockingbirdTests {
    static var allTests = [
        ("test_filter_statuscodes_range_closed_range_upperbound", test_filter_statuscodes_range_closed_range_upperbound),
        ("test_filter_statuscodes_range_closed_lowerbound", test_filter_statuscodes_range_closed_lowerbound),
        ("test_filter_statuscodes_range_upperbound", test_filter_statuscodes_range_upperbound),
        ("test_filter_statuscodes_lowerbound", test_filter_statuscodes_lowerbound),
        ("test_filter_non_success_statuscodes", test_filter_non_success_statuscodes),
        ("test_accepts_success_statuscodes", test_accepts_success_statuscodes),
        ("test_filters_failures_and_redirects", test_filters_failures_and_redirects),
        ("test_accepts_success_even_when_filtering_redirects", test_accepts_success_even_when_filtering_redirects),
        ("test_accepts_redirects", test_accepts_redirects),
        ("test_accepts_specific_statuscodes", test_accepts_specific_statuscodes),
        ("test_filters_specific_statuscodes", test_filters_specific_statuscodes),
        ("test_maps_correct_json", test_maps_correct_json),
        ("test_returns_foundation_error_for_invalid_json", test_returns_foundation_error_for_invalid_json),
        ("test_maps_data_to_string", test_maps_data_to_string),
        ("test_maps_data_in_keypath_to_string", test_maps_data_in_keypath_to_string),
        ("test_map_string_ignores_invalid_data", test_map_string_ignores_invalid_data),
        ("test_maps_json_to_decodable", test_maps_json_to_decodable),
        ("test_maps_collection_of_decodable_json", test_maps_collection_of_decodable_json),
        ("test_maps_empty_data_to_optional_decodable", test_maps_empty_data_to_optional_decodable),
        ("test_maps_empty_data_to_collection_of_optionals", test_maps_empty_data_to_collection_of_optionals),
        ("test_maps_to_decodable_with_keypath", test_maps_to_decodable_with_keypath),
        ("test_maps_to_decodable_collection_with_keypath", test_maps_to_decodable_collection_with_keypath),
        ("test_maps_empty_data_to_optional_decodable_with_keypath", test_maps_empty_data_to_optional_decodable_with_keypath),
        ("test_maps_empty_data_to_collection_of_optional_decodable_with_keypath", test_maps_empty_data_to_collection_of_optional_decodable_with_keypath),
        ("test_maps_into_int", test_maps_into_int),
        ("test_maps_into_bool", test_maps_into_bool),
        ("test_maps_into_string", test_maps_into_string),
        ("test_maps_string_into_url", test_maps_string_into_url),
        ("test_map_should_fail_from_into_to_bool", test_map_should_fail_from_into_to_bool),
        ("test_map_should_fail_string_into_int", test_map_should_fail_string_into_int),
        ("test_map_string_collection_into_string_should_fail", test_map_string_collection_into_string_should_fail),
        ("test_map_collection_string_into_string_should_fail", test_map_collection_string_into_string_should_fail),
        ("test_ignores_invalid_data", test_ignores_invalid_data)
    ]
}
