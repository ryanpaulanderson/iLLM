 // LLMChat/Utils/Constants.swift
import Foundation

enum Constants {
    /// OpenAI API base URL constructed safely via URLComponents.
    static var openAIBaseURL: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.openai.com"
        components.path = "/v1/"
        guard let url = components.url else {
            preconditionFailure("Invalid OpenAI base URL components")
        }
        return url
    }

    /// String representation of the OpenAI API base URL for contexts that require String.
    static let openAIBaseURLString = "https://api.openai.com/v1/"
}