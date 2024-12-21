//
//  DigitalValue.swift
//  HomeAPI
//
//  Created by Bill Gestrich on 11/28/24.
//

public struct DigitalValue: Codable, Sendable, Equatable {
    public let on: Bool
    
    public init(on: Bool) {
        self.on = on
    }
}
