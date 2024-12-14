//
//  PiClientAPIImplementation.swift
//  SECommon
//
//  Created by Bill Gestrich on 12/8/24.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct PiClientAPIImplementation: PiClientAPI {
    let baseURL: URL
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    public func getHost() async throws -> Host {
        let url = baseURL.appending(component: "led")
        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        return try JSONDecoder().decode(Host.self, from: data)
    }
    
    public func updateHost(ipAddress: String, port: Int) async throws -> SECommon.Host {
        let url = baseURL.appending(component: "host")
        let host = Host(ipAddress: ipAddress, port: port, uploadDate: Date())
        let hostData = try JSONEncoder().encode(host)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = hostData
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Host.self, from: data)
    }
    
    public func getLEDState() async throws -> LEDState {
        let url = baseURL.appending(component: "led")
        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        return try JSONDecoder().decode(LEDState.self, from: data)
    }

    public func updateLEDState(on: Bool) async throws -> LEDState {
        let url = baseURL.appending(component: "led")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let newState = LEDState(on: on)
        let encodedData = try JSONEncoder().encode(newState)
        request.httpBody = encodedData

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(LEDState.self, from: data)
    }
    
    public func getLightSensorReading() async throws -> LightSensorReading {
        let url = baseURL.appending(component: "lightSensorReading")
        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        return try JSONDecoder().decode(LightSensorReading.self, from: data)
    }
    
    public func updateLightSensorReading(value: Double) async throws -> LightSensorReading {
        let url = baseURL.appending(component: "lightSensorReading")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let newState = LightSensorReading(uploadDate: Date(), value: value)
        let encodedData = try JSONEncoder().encode(newState)
        request.httpBody = encodedData

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(LightSensorReading.self, from: data)
    }
    
    enum APIImplelmentationError: Error {
        case invalidURL
    }
}
