//
//  Host.swift
//  HomeAPI
//
//  Created by Bill Gestrich on 11/28/24.
//

import Foundation

public struct Host: Codable {
    public let ipAddress: String
    public let port: Int
    
    public init(ipAddress: String, port: Int){
        self.ipAddress = ipAddress
        self.port = port
    }
}
