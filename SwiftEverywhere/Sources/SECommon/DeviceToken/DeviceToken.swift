//
//  DeviceToken.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/22/24.
//

import Foundation

public struct DeviceToken: Codable, Sendable {
    public let token: String
    public let deviceName: String
    
    public init(token: String, deviceName: String) {
        self.deviceName = deviceName
        self.token = token
    }
}
