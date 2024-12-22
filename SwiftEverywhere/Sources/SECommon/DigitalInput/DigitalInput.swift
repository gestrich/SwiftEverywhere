//
//  DigitalInput.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/22/24.
//

import Foundation

public struct DigitalInput: Codable, Sendable {
    public let name: String
    public let channel: Int
    public let voltage: Voltage
}
