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

public struct PiClientAPIImplementation: PiClientAPI, Sendable {
    let baseURL: URL
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    // MARK: Analog
    
    public func getAnalogReading(channel: Int) async throws -> AnalogValue {
        let pathComponent = [PiClientAPIPaths.analogReadings.rawValue, "\(channel)"].joined(separator: "/")
        return try await getData(outputType: AnalogValue.self, urlComponent: pathComponent)
    }
    
    public func getAnalogReadings(channel: Int, range: DateRangeRequest) async throws -> [AnalogValue] {
        let pathComponent = PiClientAPIPaths.analogReadings.rawValue
        let channel = URLQueryItem(name: "channel", value: "\(channel)")
        let startQueryItem = URLQueryItem(name: "startDate", value: ISO8601DateFormatter().string(from: range.startDate))
        let endQueryItem = URLQueryItem(name: "endDate", value: ISO8601DateFormatter().string(from: range.endDate))
        return try await getData(outputType: [AnalogValue].self, urlComponent: pathComponent, queryItems: [channel, startQueryItem, endQueryItem])
    }
    
    public func updateAnalogReading(reading: AnalogValue) async throws -> AnalogValue {
        let pathComponent = [PiClientAPIPaths.analogReadings.rawValue, "\(reading.channel)"].joined(separator: "/")
        return try await postData(input: reading, outputType: AnalogValue.self, urlComponent: pathComponent)
    }
    
    // MARK: Host
    
    public func getHost() async throws -> Host {
        return try await getData(outputType: Host.self, urlComponent: PiClientAPIPaths.host.rawValue)
    }
    
    public func postHost(_ host: Host) async throws -> SECommon.Host {
        return try await postData(input: host, outputType: Host.self, urlComponent: PiClientAPIPaths.host.rawValue)
    }
    
    // MARK: LED
    
    public func getDigitalOutput(channel: Int) async throws -> DigitalValue {
        let pathComponent = [PiClientAPIPaths.digitalValues.rawValue, "\(channel)"].joined(separator: "/")
        return try await getData(outputType: DigitalValue.self .self, urlComponent: pathComponent)
    }

    public func updateDigitalReading(_ state: DigitalValue) async throws -> DigitalValue {
        return try await postData(input: state, outputType: DigitalValue.self, urlComponent: PiClientAPIPaths.digitalValues.rawValue)
    }
    
    // MARK: Utilities
    
    func postData<Input: Codable, Output: Codable>(input: Input, outputType: Output.Type, urlComponent: String) async throws -> Output {
        let url = baseURL.appendingPathComponent(urlComponent)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encodedData = try jsonEncoder.encode(input)
        request.httpBody = encodedData

        let (data, _) = try await URLSession.shared.data(for: request)
        do {
            return try jsonDecoder.decode(outputType, from: data)
        } catch {
            print(String(data: data, encoding: .utf8) ?? "")
            throw error
        }
    }
    
    func getData<Output: Codable>(outputType: Output.Type, urlComponent: String, queryItems: [URLQueryItem]? = nil) async throws -> Output {
        var url = baseURL.appendingPathComponent(urlComponent)
        if let queryItems {
            url.append(queryItems: queryItems)
        }

        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        do {
            return try jsonDecoder.decode(outputType, from: data)
        } catch {
            print(String(data: data, encoding: .utf8) ?? "")
            throw error
        }

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
