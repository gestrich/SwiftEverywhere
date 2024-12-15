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
    
    // MARK: Host
    
    public func getHost() async throws -> Host {
        return try await getData(outputType: Host.self, urlComponent: "host")
    }
    
    public func postHost(_ host: Host) async throws -> SECommon.Host {
        return try await postData(input: host, outputType: Host.self, urlComponent: "host")
    }
    
    // MARK: LED
    
    public func getLEDState() async throws -> LEDState {
        return try await getData(outputType: LEDState.self .self, urlComponent: "led")
    }

    public func updateLEDState(_ state: LEDState) async throws -> LEDState {
        return try await postData(input: state, outputType: LEDState.self, urlComponent: "led")
    }
    
    // MARK: LightSensorReading
    
    public func getLightSensorReadings(range: DateRangeRequest) async throws -> [LightSensorReading] {
        return try await postData(input: range, outputType: [LightSensorReading].self, urlComponent: "lightSensorReadings")
    }
    
    public func getLightSensorReading() async throws -> LightSensorReading {
        return try await getData(outputType: LightSensorReading.self .self, urlComponent: "lightSensorReading")
    }
    
    public func updateLightSensorReading(_ reading: LightSensorReading) async throws -> LightSensorReading {
        return try await postData(input: reading, outputType: LightSensorReading.self, urlComponent: "lightSensorReading")
    }
    
    // MARK: Utilities
    
    func postData<Input: Codable, Output: Codable>(input: Input, outputType: Output.Type, urlComponent: String) async throws -> Output {
        let url = baseURL.appending(component: urlComponent)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encodedData = try jsonEncoder.encode(input)
        request.httpBody = encodedData

        let (data, _) = try await URLSession.shared.data(for: request)
        return try jsonDecoder.decode(Output.self, from: data)
    }
    
    func getData<Output: Codable>(outputType: Output.Type, urlComponent: String) async throws -> Output {
        let url = baseURL.appending(component: urlComponent)
        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        return try jsonDecoder.decode(outputType, from: data)
    }
    
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    private var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    private enum APIImplelmentationError: Error {
        case invalidURL
    }
}
