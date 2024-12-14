//
//  Host.swift
//  HomeAPI
//
//  Created by Bill Gestrich on 11/28/24.
//

import Foundation

public struct Host: Codable {
    public let ipAddress: String
    public let port: String
    public let uploadDate: Date
    
    public init(ipAddress: String, port: String, uploadDate: Date){
        self.ipAddress = ipAddress
        self.port = port
        self.uploadDate = uploadDate
    }
}
