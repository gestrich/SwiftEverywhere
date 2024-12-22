//
//  PushNotification.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/22/24.
//


public struct PushNotification: Codable, Sendable {
    public let title: String
    public let subtitle: String
    public let message: String
    
    public init(title: String, subtitle: String, message: String) {
        self.title = title
        self.subtitle = subtitle
        self.message = message
    }
}
