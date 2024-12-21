//
//  DigitalValue.swift
//  HomeAPI
//
//  Created by Bill Gestrich on 11/28/24.
//

public struct DigitalValue: Codable, Sendable, Equatable {
    public let on: Bool
    public let channel: Int
    
    public init(on: Bool, channel: Int) {
        self.on = on
        self.channel = channel
    }
}
