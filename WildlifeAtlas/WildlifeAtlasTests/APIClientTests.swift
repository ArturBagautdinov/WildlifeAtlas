//
//  APIClientTests.swift
//  WildlifeAtlasTests
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation
import Testing
@testable import WildlifeAtlas

@Suite(.serialized)
struct APIClientTests {

    @Test func buildsURLRequestWithBaseURLQueryAndUserAgent() throws {
        let client = APIClient(
            baseURL: try #require(URL(string: "https://api.inaturalist.org/v1")),
            userAgent: "WildlifeAtlasTests/1.0"
        )
        let endpoint = APIEndpoint(
            path: "observations",
            queryItems: [URLQueryItem(name: "captive", value: "false")]
        )

        let request = try client.makeURLRequest(for: endpoint)

        #expect(request.url?.absoluteString == "https://api.inaturalist.org/v1/observations?captive=false")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "WildlifeAtlasTests/1.0")
    }

    @Test func requestDecodesSuccessfulResponse() async throws {
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data(#"{"value":"ok"}"#.utf8)
            return (response, data)
        }
        defer { URLProtocolStub.requestHandler = nil }

        let value: TestResponse = try await makeClient().request(APIEndpoint(path: "test"))

        #expect(value.value == "ok")
    }

    @Test func requestMapsHTTPStatusFailures() async throws {
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        defer { URLProtocolStub.requestHandler = nil }

        do {
            let _: TestResponse = try await makeClient().request(APIEndpoint(path: "test"))
            Issue.record("Expected HTTP status failure")
        } catch let error as APIError {
            #expect(error == .httpStatus(500))
        }
    }

    @Test func requestMapsDecodingFailures() async throws {
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(#"{"unexpected":"shape"}"#.utf8))
        }
        defer { URLProtocolStub.requestHandler = nil }

        do {
            let _: TestResponse = try await makeClient().request(APIEndpoint(path: "test"))
            Issue.record("Expected decoding failure")
        } catch let error as APIError {
            if case .decoding = error {
                #expect(true)
            } else {
                Issue.record("Expected decoding error, got \(error)")
            }
        }
    }

    @Test func requestMapsTransportFailures() async throws {
        URLProtocolStub.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        defer { URLProtocolStub.requestHandler = nil }

        do {
            let _: TestResponse = try await makeClient().request(APIEndpoint(path: "test"))
            Issue.record("Expected transport failure")
        } catch let error as APIError {
            if case .transport = error {
                #expect(true)
            } else {
                Issue.record("Expected transport error, got \(error)")
            }
        }
    }

    private func makeClient() -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        return APIClient(
            baseURL: URL(string: "https://example.com/api")!,
            session: session,
            userAgent: "WildlifeAtlasTests/1.0"
        )
    }
}

private struct TestResponse: Decodable, Equatable {
    let value: String
}

private final class URLProtocolStub: URLProtocol {
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
