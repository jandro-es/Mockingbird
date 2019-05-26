<img src="images/mockingbird-logo.png">

[![CircleCI](https://circleci.com/gh/jandro-es/Mockingbird/tree/master.svg?style=svg)](https://circleci.com/gh/jandro-es/Mockingbird/tree/master)
[![codecov](https://codecov.io/gh/jandro-es/Mockingbird/branch/master/graph/badge.svg)](https://codecov.io/gh/jandro-es/Mockingbird)  [![GitHub](https://img.shields.io/github/license/jandro-es/Mockingbird.svg)](https://github.com/jandro-es/Mockingbird/blob/master/LICENSE)  [![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)  ![Cocoapods](https://img.shields.io/cocoapods/v/Mockingbird-Swift.svg)  ![Cocoapods platforms](https://img.shields.io/cocoapods/p/Mockingbird-Swift.svg)

# Mockingbird

**Mockingbird** is a **N**etwork **A**bstraction **L**ayer *(NAL)* written in swift leveraging the power and versatility of *Foundation's* **URLSession**. It's compatible with **iOS** version *9* or greater and **macOS** version *10.12* or greater.

It draws inspiration from [Moya](https://github.com/Moya/Moya) and [Alamofire](https://github.com/Alamofire/Alamofire) with a focus in easier integration and unit testing of the network layer.

## Table of contents
- [Mockingbird](#mockingbird)
  - [Table of contents](#table-of-contents)
  - [Installation](#installation)
    - [Cocoapods](#cocoapods)
    - [Swift Package Manager](#swift-package-manager)
  - [Architecture](#architecture)
  - [Using Mockingbird](#using-mockingbird)
    - [Defining a remote API](#defining-a-remote-api)
      - [baseURL](#baseurl)
      - [path](#path)
      - [method](#method)
      - [requestType](#requesttype)
      - [testData](#testdata)
      - [validation](#validation)
      - [headers](#headers)
    - [Initialising a Mockingbird instance](#initialising-a-mockingbird-instance)
    - [Requesting data](#requesting-data)
      - [Using closures](#using-closures)
      - [Using RxSwift](#using-rxswift)
    - [Middleware](#middleware)
      - [Authentication Token Middleware](#authentication-token-middleware)
      - [Network Activity Middleware](#network-activity-middleware)
  - [Logging](#logging)
  - [Comming soon](#comming-soon)
  - [Contributing](#contributing)
  - [License](#license)

## Installation

At the moment only **Cocoapods** and **Swift Package Manager SPM** are supported, with support for *Carthage* comming soon.
**Swift 4.x** and **Xcode 10.x** are required to build it.

### Cocoapods

To install `Mockingird` using **Cocoapods** just add it to your project's `Podfile`:

```bash
 pod 'Mockingbird-Swift'
```

and if you want to use the **RxSwift** extensions add them:

```bash
pod 'Mockingbird-Swift/RxSwift'
```

To use the library in your application please import the Swift module as follows:

```swift
import Mockingbird_Swift
```

### Swift Package Manager

Just add `Mockingbird` as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/jandro-es/Mockingbird", .upToNextMajor(from: "1.0.0"))
]
```

## Architecture

**Mockingbird** simplifies the creation of a network layer in your application. You can define your entire layer in a declarative way by implementing the `RemoteServiceType` protocol in your different types. Generating a simple map of your network endpoints. Mockingbird uses `URLSession` as it's undelying network system, exposing it's configuration, allowing you to customise it, among many other customisations, as needed.
A simplified architecture diagram *(please have a look at the code for more details)*:

<img src="images/mockingbird-architecture.png">

## Using Mockingbird

### Defining a remote API

The first step when building your network layer would be to define, in a declarative way, the *service* or *API* you want to interact with. For defining these remote APIs you can use **Enum**, **Struct** or **Class**, but we've found out that the clearest one is using an **Enum** but it might be different in your use case.
To declare an API we need to implement the protocol [RemoteService](Sources/Mockingbird/RemoteService.swift). A simple example will be as:

```swift
enum GitHub {
    case zen
    case userProfile(String)
}

extension GitHub: RemoteServiceType {

    var baseURL: URL {
        return URL(string: "https://api.github.com")!
    }
    var path: String {
        switch self {
        case .zen:
            return "/zen"
        case .userProfile(let name):
            return "/users/\(name)"
        }
    }

    var method: HTTPMethod {
        return .get
    }

    var requestType: RequestType {
        switch self {
        case .zen, .userProfile:
            return .plain
        }
    }

    var testData: Data {
        switch self {
        case .zen:
            return "The hardest thing in this world is to live in it".data(using: String.Encoding.utf8)!
        case .userProfile(let name):
            return "{\"login\": \"\(name)\", \"id\": 123456}".data(using: String.Encoding.utf8)!
        }
    }

    var validation: RequestValidation {
        return .successAndRedirectCodes
    }

    var headers: [String: String]? {
        return nil
    }
}
```

This example declares an interface for the GitHub API, with two endpoints, `.zen` and `userProfile`. Let's see step by step each one of the requirements.

#### baseURL

As it's name indicates, this is the base URL of the API. We could have different bases per endpoint (using enums) but that's considered a bad practice, is better to declare different services per base URL. The base URL should contain the protocol information.

#### path

This is the fully qualified path of the endpoint, containing all the URL parameters needed (not query string ones). Mockingbird **does not escape** those parameters automatically.

#### method

This is the HTTP method / verb to use for the request. Mockingbird provides as an enum the following values:

- GET
- POST
- PATCH
- PUT
- DELETE
- HEAD

#### requestType

This is the type of request Mockingbird should do, meaning how to prepare the request **and** how to proccess the responnse. The available request types are:

- plain: Simple `Request`
- data: The `Request` has a body with `Data`
- JSONEncodable: The `Request` has a body with an `Encodable` object
- customJSONEncodable: The `Request` has a body with an `Encodable` object using a custom `JSONEncoder`
- parameters: The request has a collection of URL parameters using a `ParameterEncodingType` as encoder
- compositeData: The request has a collection of URL parameters and a body with `Data` type
- compositeParameters: The request has a combination of body parameters (encoded as `Data`) and URL parameters
- download: The request is for downloading a file
- downloadParameters: The request is for downloading a file with URL parameters

#### testData

This is the `Data` object to return, for the requested endpoint when using **stubbing**. It can be useful for testing, or even for development under contract agreement.

#### validation

Mockingbird automatically validates the response based on the required validation technique. This allows to simplify your error management code. The available validation techniques are:

- none: No validation
- successCodes: Standard HTTP success codes (200,...,299)
- successAndRedirectCodes: Standard HTTP success and redirect codes (200,...,399)
- customCodes: Custom collection of valid HTTP codes

#### headers

This is just an optional dictionary of HTTP headers to add to the request.

### Initialising a Mockingbird instance

It can be quite simple, if you're happy using the [defaults](Sources/Mockingbird/Extensions/Mockingbird%2BDefaults.swift) you just need to let the swift compiler know the type:

```swift

let githubAPI = Mockingbird<GithubAPI>()

```

Mockingbird instances allow for a lot of customisation and / or configuration, if you want to know all the options I recommend having a look at the tests, as all of the possible cases are covered there.

The most common scenarios when initialising Mockingbird are:

```swift

let githubAPI = Mockingbird<GithubAPI>(middleware: [Middleware.networkActivityIndicator])

```

Creates an instance for `GithubAPI` with the given **Middleware**.

```swift

let githubAPI = Mockingbird<GithubAPI>(sessionConfiguration: configuration)

```

Creates an instance for `GithubAPI` using the given **URLSessionConfiguration**.

``` swift

let githubAPI = Mockingbird<GithubAPI>(stubLambda: Mockingbird.immediatelyStub)

```

Creates an instance for `GithubAPI` that retuns, without delay, a stub. This stub is the `testData` declared in the `GithubAPI` enum.

### Requesting data

#### Using closures

When using **closures** as the return technique, it returns a `Result` type that has `success(value)` and an `failure(error)` cases.

```swift

githubAPI.request(.zen) { result in
    switch result {
    case let .success(response):
      print("data: \(response.data)")
    case let .failure(mockingbirdError):
      print("error: \(mockingbirdError)")
    }
}

```

#### Using RxSwift

[RxSwift](https://github.com/ReactiveX/RxSwift) extensions are provided out of the box. To use them when requesting data:

```swift

githubAPI.rx.request(.zen)
.subscribe { event in
  switch event {
  case .success(let response):
      print("data: \(response.data)")
  case .error:
      print("error: \(mockingbirdError)")
}

```

Using RxSwift allows for a clean validation and manipulation using the available [Rx operators](https://github.com/jandro-es/Mockingbird/blob/master/Sources/RxMockingbird/Observable%2BResponse.swift).


### Middleware

Middleware is a powerful way of adding logging, authentication tokens and / or modifying your requests and responses in a clean and decoupled way. It's defined by the protocol [MiddlewareType](Sources/Mockingbird/Middleware.swift). Two middleware types are included:

#### Authentication Token Middleware

This middleware allows you to automatically add an authentication token to all the requests that need it. It's defined in [AccessTokenMiddleware](Sources/Mockingbird/Middleware/AccessTokenMiddleware.swift). The supported types of auth token are:

- none: No AccessToken
- basic: `Basic` AccessToken
- bearer: `Bearer` AccessToken
- custom: `custom` AccessToken

To have a look on how to use it have a look at the tests in [MockingbirdIntegrationTests](Tests/MockingbirdTests/MockingbirdIntegrationTests.swift).

#### Network Activity Middleware

This middleware executes a block when the actual network request starts, and finishes. Allowing the user to for example update the UI. One common example in iOS is to show and hide the `NetworkActivityIndicator`.

```swift

static var networkActivityIndicator: NetworkActivityMiddleware {
  return NetworkActivityMiddleware { status, _ in
      switch status {
      case .began:
          DispatchQueue.main.async {
              UIApplication.shared.isNetworkActivityIndicatorVisible = true
          }
      case .ended:
          DispatchQueue.main.async {
              UIApplication.shared.isNetworkActivityIndicatorVisible = false
          }
      }
  }
}

```

## Logging

Mockingbird uses [Apple's Unified Logging](https://developer.apple.com/documentation/os/logging).
| Subsystem | Category |
| ------------- | ------------- |
| com.filtercode.mockingbird | request_operation |
| com.filtercode.mockingbird | request |
| com.filtercode.mockingbird | response |
| com.filtercode.mockingbird | middleware |

## Comming soon

- Multipart upload
- Download progress

## Contributing

## License

This project is released under [MIT](LICENSE.md) license.