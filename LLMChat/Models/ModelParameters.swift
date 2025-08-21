//
//  ModelParameters.swift
//  LLMChat
//
//  Created by AI Agent.
//  Description: Model parameters for controlling LLM behavior like temperature and top-p
//

import Foundation

/// Parameters that control LLM response generation behavior.
struct ModelParameters: Codable, Equatable {
    /// Controls randomness: 0.0 = deterministic, 1.0 = very creative. Optional - not sent if nil.
    var temperature: Double?
    
    /// Controls nucleus sampling: 0.1 = only top 10% likely tokens, 1.0 = all tokens. Optional - not sent if nil.
    var topP: Double?
    
    /// Default parameters with reasonable values for most use cases.
    static let defaultValues = ModelParameters(temperature: 0.7, topP: 0.9)
    
    /// Empty parameters (sends no parameters to the model, uses provider defaults).
    static let empty = ModelParameters(temperature: nil, topP: nil)
    
    /// Creates model parameters.
    /// - Parameters:
    ///   - temperature: Randomness control (0.0-2.0, typically 0.1-1.0)
    ///   - topP: Nucleus sampling (0.0-1.0)
    init(temperature: Double? = nil, topP: Double? = nil) {
        self.temperature = temperature
        self.topP = topP
    }
}
