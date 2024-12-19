//
//  PiHardwareConfiguration.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/19/24.
//

import Foundation

public struct PiHardwareConfiguration: Sendable {
    public let sensorConfigurations: [AnalogSensorConfiguration]
    
    public init() {
        self.sensorConfigurations = [
            AnalogSensorConfiguration(name: "Light", channel: 1),
            AnalogSensorConfiguration(name: "Temperature", channel: 2),
        ]
    }
}

public struct AnalogSensorConfiguration: Sendable {
    public let name: String
    public let channel: Int
}
