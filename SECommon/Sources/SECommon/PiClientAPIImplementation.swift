//
//  PiClientAPIImplementation.swift
//  SECommon
//
//  Created by Bill Gestrich on 12/8/24.
//

import Foundation

public struct PiClientAPIImplementation: PiClientAPI {
    let baseURL: URL
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    public func getLEDState() async throws -> LEDState {
        guard let url = URL(string: "\(baseURL)/led") else {
            throw APIImplelmentationError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        return try JSONDecoder().decode(LEDState.self, from: data)
    }

    public func updateLEDState(on: Bool) async throws -> LEDState {
        guard let url = URL(string: "\(baseURL)/led") else {
            print("Invalid URL")
            throw APIImplelmentationError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let newState = LEDState(on: on)
        let encodedData = try JSONEncoder().encode(newState)
        request.httpBody = encodedData

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(LEDState.self, from: data)
    }
    
    enum APIImplelmentationError: Error {
        case invalidURL
    }
}
