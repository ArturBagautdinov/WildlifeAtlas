//
//  ImageLoaderTests.swift
//  WildlifeAtlasTests
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation
import Testing
import UIKit
@testable import WildlifeAtlas

@Suite(.serialized)
struct ImageLoaderTests {

    @Test func successfulResponseDecodesAndCachesImage() async throws {
        let requestCounter = RequestCounter()
        ImageURLProtocolStub.requestHandler = { request in
            requestCounter.increment()
            return try Self.imageResponse(for: request, statusCode: 200)
        }
        defer { ImageURLProtocolStub.requestHandler = nil }

        let loader = makeLoader()
        let url = try #require(URL(string: "https://example.com/image.png"))

        let firstImage = try await loader.image(from: url)
        let secondImage = try await loader.image(from: url)

        #expect(firstImage.size == CGSize(width: 1, height: 1))
        #expect(secondImage.size == CGSize(width: 1, height: 1))
        #expect(requestCounter.value == 1)
    }

    @Test func concurrentRequestsForSameURLShareOneDownload() async throws {
        let requestCounter = RequestCounter()
        ImageURLProtocolStub.requestHandler = { request in
            requestCounter.increment()
            Thread.sleep(forTimeInterval: 0.1)
            return try Self.imageResponse(for: request, statusCode: 200)
        }
        defer { ImageURLProtocolStub.requestHandler = nil }

        let loader = makeLoader()
        let url = try #require(URL(string: "https://example.com/shared.png"))

        async let firstImage = loader.image(from: url)
        async let secondImage = loader.image(from: url)

        let images = try await [firstImage, secondImage]

        #expect(images.count == 2)
        #expect(requestCounter.value == 1)
    }

    @Test func httpFailureDoesNotCacheFailedResponse() async throws {
        let requestCounter = RequestCounter()
        ImageURLProtocolStub.requestHandler = { request in
            requestCounter.increment()
            return try Self.imageResponse(for: request, statusCode: 404)
        }
        defer { ImageURLProtocolStub.requestHandler = nil }

        let loader = makeLoader()
        let url = try #require(URL(string: "https://example.com/missing.png"))

        for _ in 0..<2 {
            do {
                _ = try await loader.image(from: url)
                Issue.record("Expected HTTP failure")
            } catch let error as ImageLoadingError {
                #expect(error == .httpStatus(404))
            }
        }

        #expect(requestCounter.value == 2)
    }

    @Test func invalidImageDataMapsToImageError() async throws {
        ImageURLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("not an image".utf8))
        }
        defer { ImageURLProtocolStub.requestHandler = nil }

        do {
            _ = try await makeLoader().image(from: try #require(URL(string: "https://example.com/bad.png")))
            Issue.record("Expected invalid image data failure")
        } catch let error as ImageLoadingError {
            #expect(error == .invalidImageData)
        }
    }

    @Test func invalidURLFailsBeforeStartingRequest() async throws {
        let requestCounter = RequestCounter()
        ImageURLProtocolStub.requestHandler = { request in
            requestCounter.increment()
            return try Self.imageResponse(for: request, statusCode: 200)
        }
        defer { ImageURLProtocolStub.requestHandler = nil }

        do {
            _ = try await makeLoader().image(from: URL(fileURLWithPath: "/tmp/image.png"))
            Issue.record("Expected invalid URL failure")
        } catch let error as ImageLoadingError {
            #expect(error == .invalidURL)
        }

        #expect(requestCounter.value == 0)
    }

    @Test func transportFailureMapsToImageError() async throws {
        ImageURLProtocolStub.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        defer { ImageURLProtocolStub.requestHandler = nil }

        do {
            _ = try await makeLoader().image(from: try #require(URL(string: "https://example.com/offline.png")))
            Issue.record("Expected transport failure")
        } catch let error as ImageLoadingError {
            if case .transport = error {
                return
            } else {
                Issue.record("Expected transport error, got \(error)")
            }
        }
    }

    private func makeLoader() -> RemoteImageLoader {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ImageURLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let cache = NSCache<NSURL, UIImage>()
        return RemoteImageLoader(session: session, cache: cache)
    }

    private static func imageResponse(
        for request: URLRequest,
        statusCode: Int
    ) throws -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: try #require(request.url),
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "image/png"]
        )!
        return (response, pngImageData)
    }

    private static let pngImageData = Data(base64Encoded:
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="
    )!
}

private final class RequestCounter {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        count += 1
    }
}

private final class ImageURLProtocolStub: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
