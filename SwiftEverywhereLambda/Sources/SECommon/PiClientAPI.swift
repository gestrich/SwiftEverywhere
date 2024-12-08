//
//  PiClientAPI.swift
//  SECommon
//
//  Created by Bill Gestrich on 12/8/24.
//

import Foundation

public protocol PiClientAPI {
    func getLEDState() async throws -> LEDState
    func updateLEDState(on: Bool) async throws -> LEDState
}
