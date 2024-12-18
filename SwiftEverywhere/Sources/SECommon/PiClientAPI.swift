//
//  PiClientAPI.swift
//  SECommon
//
//  Created by Bill Gestrich on 12/8/24.
//

import Foundation

public protocol PiClientAPI {
    func getAnalogReading(channel: Int) async throws -> AnalogReading
    func getAnalogReadings(channel: Int, range: DateRangeRequest) async throws -> [AnalogReading]
    func updateAnalogReading(reading: AnalogReading) async throws -> AnalogReading
    func getLEDState() async throws -> LEDState
    func updateLEDState(_ state: LEDState) async throws -> LEDState
    func getHost() async throws -> Host
    func postHost(_ host: Host) async throws -> Host
    func getLightSensorReading() async throws -> LightSensorReading
    func getLightSensorReadings(range: DateRangeRequest) async throws -> [LightSensorReading]
    func updateLightSensorReading(_ reading: LightSensorReading) async throws -> LightSensorReading
}

public enum PiClientAPIPaths: String, CaseIterable {
    case analogReadings
    case host
    case led
    case lightSensorReading
    case lightSensorReadings
}
