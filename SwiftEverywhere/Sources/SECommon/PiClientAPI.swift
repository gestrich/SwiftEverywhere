//
//  PiClientAPI.swift
//  SECommon
//
//  Created by Bill Gestrich on 12/8/24.
//

import Foundation

public protocol PiClientAPI {
    func getAnalogReading(channel: Int) async throws -> AnalogValue
    func getAnalogReadings(channel: Int, range: DateRangeRequest) async throws -> [AnalogValue]
    func updateAnalogReading(reading: AnalogValue) async throws -> AnalogValue
    func getDigitalOutput(channel: Int) async throws -> DigitalValue
    func updateDigitalReading(_ state: DigitalValue) async throws -> DigitalValue
    func getHost() async throws -> Host
    func postHost(_ host: Host) async throws -> Host
}

public enum PiClientAPIPaths: String, CaseIterable {
    case analogReadings
    case digitalValues
    case host
}
