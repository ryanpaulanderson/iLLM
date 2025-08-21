//
//  NetworkManagerTests.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Unit tests for NetworkManager HTTP client and error handling.
//

import XCTest
@testable import LLMChat

final class NetworkManagerTests: XCTestCase {
    
    private var networkManager: NetworkManager!
    
    override func setUp() {
        super.setUp()
        networkManager = NetworkManager()
    }
    
    override func tearDown() {
        networkManager = nil
        super.tearDown()
    }
    
    // MARK: - NetworkRequest Construction Tests
    
    func test_networkRequest_withJSONBody_encodesCorrectly() throws {
        // Given
        struct TestBody: Codable {
            let message: String
            let count: Int
        }
        let testBody = TestBody(message: "hello", count: 42)
        let url = URL(string: "https://api.example.com/test")!
        
        // When
        let request = try NetworkRequest(
            url: url,
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: testBody
        )
        
        // Then
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        XCTAssertNotNil(request.bodyData)
        
        // Verify JSON encoding
        let decoded = try JSONDecoder().decode(TestBody.self, from: request.bodyData!)
        XCTAssertEqual(decoded.message, "hello")
        XCTAssertEqual(decoded.count, 42)
    }
    
    func test_networkRequest_withNilBody_hasNilBodyData() throws {
        // Given
        let url = URL(string: "https://api.example.com/test")!
        
        // When
        let request = try NetworkRequest(
            url: url,
            method: .get,
            headers: [:],
            body: Optional<String>.none
        )
        
        // Then
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.method, .get)
        XCTAssertNil(request.bodyData)
    }
    
    func test_networkRequest_withDateInBody_usesISO8601Encoding() throws {
        // Given
        struct TestBody: Encodable {
            let timestamp: Date
        }
        let testDate = Date(timeIntervalSince1970: 1640995200) // 2022-01-01T00:00:00Z
        let testBody = TestBody(timestamp: testDate)
        let url = URL(string: "https://api.example.com/test")!
        
        // When
        let request = try NetworkRequest(url: url, method: .post, body: testBody)
        
        // Then
        XCTAssertNotNil(request.bodyData)
        let jsonString = String(data: request.bodyData!, encoding: .utf8)!
        XCTAssertTrue(jsonString.contains("2022-01-01T00:00:00Z"))
    }
    
    // MARK: - HTTPMethod Tests
    
    func test_httpMethod_rawValues() {
        XCTAssertEqual(HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.post.rawValue, "POST")
    }
    
    // MARK: - Integration Tests with Mock Server
    
    // Note: These tests would ideally use a mock HTTP server or URLProtocol subclass
    // For now, we're testing the request construction and error handling logic
    
    func test_request_buildsURLRequestCorrectly() async {
        // Given
        struct TestResponse: Decodable {
            let success: Bool
        }
        
        struct TestBody: Encodable {
            let data: String
        }
        
        let url = URL(string: "https://httpbin.org/post")! // Real endpoint for testing
        let testBody = TestBody(data: "test")
        let request = try! NetworkRequest(
            url: url,
            method: .post,
            headers: [
                "Content-Type": "application/json",
                "User-Agent": "LLMChat-Tests"
            ],
            body: testBody
        )
        
        // We can't easily test successful requests without a mock server
        // But we can verify the request is constructed properly by checking it doesn't throw
        // during construction
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.method, .post)
        XCTAssertNotNil(request.bodyData)
    }
    
    // MARK: - Error Handling Tests
    
    func test_appError_equality() {
        // Given
        let error1 = AppError.network(description: "Connection failed")
        let error2 = AppError.network(description: "Connection failed")
        let error3 = AppError.network(description: "Different error")
        let httpError1 = AppError.httpStatus(code: 404, body: "Not found")
        let httpError2 = AppError.httpStatus(code: 404, body: "Not found")
        
        // When & Then
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
        XCTAssertEqual(httpError1, httpError2)
        XCTAssertNotEqual(error1, httpError1)
    }
    
    func test_appError_errorDescriptions() {
        // Given
        let networkError = AppError.network(description: "Network issue")
        let httpError = AppError.httpStatus(code: 500, body: "Server error")
        let keychainError = AppError.keychain(status: errSecItemNotFound)
        let decodingError = AppError.decoding(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Test")))
        let unknownError = AppError.unknown(NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"]))
        
        // When & Then
        XCTAssertEqual(networkError.errorDescription, "Network issue")
        XCTAssertEqual(httpError.errorDescription, "HTTP 500: Server error")
        XCTAssertEqual(keychainError.errorDescription, "Keychain error: \(errSecItemNotFound)")
        XCTAssertTrue(decodingError.errorDescription?.contains("Decoding error") ?? false)
        XCTAssertTrue(unknownError.errorDescription?.contains("Unknown error") ?? false)
    }
    
    func test_appError_identifiableConformance() {
        // Given
        let error1 = AppError.network(description: "Test")
        let error2 = AppError.httpStatus(code: 404, body: "Not found")
        
        // When & Then
        XCTAssertEqual(error1.id, error1.localizedDescription)
        XCTAssertEqual(error2.id, error2.localizedDescription)
        XCTAssertNotEqual(error1.id, error2.id)
    }
}
