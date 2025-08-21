//
//  ModelsTests.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Unit tests for data models, Codable conformance, and computed properties.
//

import XCTest
@testable import LLMChat

final class ModelsTests: XCTestCase {
    
    // MARK: - Message Tests
    
    func test_message_initialization_setsPropertiesCorrectly() {
        // Given
        let id = UUID()
        let content = "Test message"
        let role = MessageRole.user
        let timestamp = Date()
        
        // When
        let message = Message(id: id, content: content, role: role, timestamp: timestamp)
        
        // Then
        XCTAssertEqual(message.id, id)
        XCTAssertEqual(message.content, content)
        XCTAssertEqual(message.role, role)
        XCTAssertEqual(message.timestamp, timestamp)
    }
    
    func test_message_defaultValues_useCurrentDateAndRandomID() {
        // Given & When
        let message = Message(content: "Test", role: .user)
        
        // Then
        XCTAssertFalse(message.id.uuidString.isEmpty)
        XCTAssertEqual(message.content, "Test")
        XCTAssertEqual(message.role, .user)
        // Timestamp should be recent (within last second)
        XCTAssertLessThan(abs(message.timestamp.timeIntervalSinceNow), 1.0)
    }
    
    func test_message_isFromUser_returnsCorrectValue() {
        // Given
        let userMessage = Message(content: "User", role: .user)
        let assistantMessage = Message(content: "Assistant", role: .assistant)
        let systemMessage = Message(content: "System", role: .system)
        
        // When & Then
        XCTAssertTrue(userMessage.isFromUser)
        XCTAssertFalse(assistantMessage.isFromUser)
        XCTAssertFalse(systemMessage.isFromUser)
    }
    
    func test_message_codableConformance() throws {
        // Given
        let originalMessage = Message(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789abc")!,
            content: "Test message",
            role: .assistant,
            timestamp: Date(timeIntervalSince1970: 1640995200)
        )
        
        // When
        let encoded = try JSONEncoder().encode(originalMessage)
        let decoded = try JSONDecoder().decode(Message.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.id, originalMessage.id)
        XCTAssertEqual(decoded.content, originalMessage.content)
        XCTAssertEqual(decoded.role, originalMessage.role)
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970, originalMessage.timestamp.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func test_message_hashableConformance() {
        // Given
        let message1 = Message(id: UUID(), content: "Test", role: .user, timestamp: Date())
        let message2 = Message(id: message1.id, content: message1.content, role: message1.role, timestamp: message1.timestamp)
        let message3 = Message(content: "Different", role: .user)
        
        // When & Then
        XCTAssertEqual(message1, message2)
        XCTAssertNotEqual(message1, message3)
        
        let set = Set([message1, message2, message3])
        XCTAssertEqual(set.count, 2) // message1 and message2 should be treated as same
    }
    
    // MARK: - MessageRole Tests
    
    func test_messageRole_rawValues() {
        XCTAssertEqual(MessageRole.system.rawValue, "system")
        XCTAssertEqual(MessageRole.user.rawValue, "user")
        XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
    }
    
    func test_messageRole_caseIterable() {
        let allCases = MessageRole.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.system))
        XCTAssertTrue(allCases.contains(.user))
        XCTAssertTrue(allCases.contains(.assistant))
    }
    
    func test_messageRole_codableConformance() throws {
        // Given
        let roles: [MessageRole] = [.system, .user, .assistant]
        
        for role in roles {
            // When
            let encoded = try JSONEncoder().encode(role)
            let decoded = try JSONDecoder().decode(MessageRole.self, from: encoded)
            
            // Then
            XCTAssertEqual(decoded, role)
        }
    }
    
    // MARK: - Conversation Tests
    
    func test_conversation_initialization_setsPropertiesCorrectly() {
        // Given
        let id = UUID()
        let title = "Test Conversation"
        let lastMessage = "Last message content"
        let timestamp = Date()
        let isActive = true
        let modelID = "gpt-4o"
        
        // When
        let conversation = Conversation(
            id: id,
            title: title,
            lastMessage: lastMessage,
            timestamp: timestamp,
            isActive: isActive,
            lastUsedModelID: modelID
        )
        
        // Then
        XCTAssertEqual(conversation.id, id)
        XCTAssertEqual(conversation.title, title)
        XCTAssertEqual(conversation.lastMessage, lastMessage)
        XCTAssertEqual(conversation.timestamp, timestamp)
        XCTAssertEqual(conversation.isActive, isActive)
        XCTAssertEqual(conversation.lastUsedModelID, modelID)
    }
    
    func test_conversation_defaultValues() {
        // Given & When
        let conversation = Conversation(title: "Test")
        
        // Then
        XCTAssertFalse(conversation.id.uuidString.isEmpty)
        XCTAssertEqual(conversation.title, "Test")
        XCTAssertNil(conversation.lastMessage)
        XCTAssertLessThan(abs(conversation.timestamp.timeIntervalSinceNow), 1.0)
        XCTAssertFalse(conversation.isActive)
        XCTAssertNil(conversation.lastUsedModelID)
    }
    
    func test_conversation_codableConformance() throws {
        // Given
        let originalConversation = Conversation(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789abc")!,
            title: "Test Chat",
            lastMessage: "Hello world",
            timestamp: Date(timeIntervalSince1970: 1640995200),
            isActive: true,
            lastUsedModelID: "gpt-4o"
        )
        
        // When
        let encoded = try JSONEncoder().encode(originalConversation)
        let decoded = try JSONDecoder().decode(Conversation.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.id, originalConversation.id)
        XCTAssertEqual(decoded.title, originalConversation.title)
        XCTAssertEqual(decoded.lastMessage, originalConversation.lastMessage)
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970, originalConversation.timestamp.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(decoded.isActive, originalConversation.isActive)
        XCTAssertEqual(decoded.lastUsedModelID, originalConversation.lastUsedModelID)
    }
    
    // MARK: - LLMModel Tests
    
    func test_llmModel_initialization() {
        // Given
        let id = "gpt-4o"
        let name = "GPT-4o"
        let provider = "openai"
        
        // When
        let model = LLMModel(id: id, name: name, provider: provider)
        
        // Then
        XCTAssertEqual(model.id, id)
        XCTAssertEqual(model.name, name)
        XCTAssertEqual(model.provider, provider)
    }
    
    func test_llmModel_codableConformance() throws {
        // Given
        let originalModel = LLMModel(id: "gpt-4o", name: "GPT-4o", provider: "openai")
        
        // When
        let encoded = try JSONEncoder().encode(originalModel)
        let decoded = try JSONDecoder().decode(LLMModel.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.id, originalModel.id)
        XCTAssertEqual(decoded.name, originalModel.name)
        XCTAssertEqual(decoded.provider, originalModel.provider)
    }
    
    // MARK: - ModelParameters Tests
    
    func test_modelParameters_empty_hasNilValues() {
        // When
        let empty = ModelParameters.empty
        
        // Then
        XCTAssertNil(empty.temperature)
        XCTAssertNil(empty.topP)
    }
    
    func test_modelParameters_initialization() {
        // Given
        let temperature = 0.7
        let topP = 0.9
        
        // When
        let parameters = ModelParameters(temperature: temperature, topP: topP)
        
        // Then
        XCTAssertEqual(parameters.temperature, temperature)
        XCTAssertEqual(parameters.topP, topP)
    }
    
    func test_modelParameters_codableConformance() throws {
        // Given
        let originalParameters = ModelParameters(temperature: 0.8, topP: 0.95)
        
        // When
        let encoded = try JSONEncoder().encode(originalParameters)
        let decoded = try JSONDecoder().decode(ModelParameters.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.temperature, originalParameters.temperature)
        XCTAssertEqual(decoded.topP, originalParameters.topP)
    }
    
    func test_modelParameters_equatableConformance() {
        // Given
        let params1 = ModelParameters(temperature: 0.7, topP: 0.9)
        let params2 = ModelParameters(temperature: 0.7, topP: 0.9)
        let params3 = ModelParameters(temperature: 0.8, topP: 0.9)
        let empty1 = ModelParameters.empty
        let empty2 = ModelParameters.empty
        
        // When & Then
        XCTAssertEqual(params1, params2)
        XCTAssertNotEqual(params1, params3)
        XCTAssertEqual(empty1, empty2)
        XCTAssertNotEqual(params1, empty1)
    }
    
    // MARK: - APIConfiguration Tests
    
    func test_apiConfiguration_initialization() {
        // Given
        let baseURL = URL(string: "https://api.openai.com/v1")!
        let apiKey = "test-key"
        let provider = "openai"
        
        // When
        let config = APIConfiguration(baseURL: baseURL, apiKey: apiKey, provider: provider)
        
        // Then
        XCTAssertEqual(config.baseURL, baseURL)
        XCTAssertEqual(config.apiKey, apiKey)
        XCTAssertEqual(config.provider, provider)
    }
    
    func test_apiConfiguration_defaultInitialization() {
        // When
        let config = APIConfiguration()
        
        // Then
        XCTAssertEqual(config.baseURL, Constants.openAIBaseURL)
        XCTAssertEqual(config.apiKey, "")
        XCTAssertEqual(config.provider, "openai")
    }
}
