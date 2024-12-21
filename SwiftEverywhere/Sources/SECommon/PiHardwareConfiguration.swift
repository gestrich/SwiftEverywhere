//
//  PiHardwareConfiguration.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/19/24.
//

import Foundation

public struct PiHardwareConfiguration: Sendable {
    public let analogInputs: [AnalogInput]
    public let digitalOutputs: [DigitalOutput]
    
    public init() {
        self.analogInputs = [
            AnalogInput(
                name: "Light",
                channel: 1,
                voltage: .v3_3,
                valueInterpretation: .reverse
            ),
            AnalogInput(
                name: "Temperature",
                channel: 2,
                voltage: .v3_3,
                valueInterpretation: .reverse
            ),
            AnalogInput(
                name: "Temperature 2",
                channel: 0,
                voltage: .v3_3,
                valueInterpretation: .reverse
            ),
        ]
        
        self.digitalOutputs = [
            DigitalOutput(
                name: "Red LED",
                channel: 20,
                voltage: .v3_3
                ),
            DigitalOutput(
                name: "Blue LED",
                channel: 21,
                voltage: .v3_3
                )
            ]
    }
}
