//
//  DigitalOutput.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/21/24.
//

import Foundation

public struct DigitalOutput: Codable, Sendable {
    public let name: String
    public let channel: Int
    public let voltage: Voltage
}
