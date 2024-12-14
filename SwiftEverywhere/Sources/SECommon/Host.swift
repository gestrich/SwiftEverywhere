//
//  Host.swift
//  HomeAPI
//
//  Created by Bill Gestrich on 11/28/24.
//

import Foundation

public struct Host: Codable {
    public let ipAddress: String
    public let uploadDate: Date
    
    public init(ipAddress: String, uploadDate: Date){
        self.ipAddress = ipAddress
        self.uploadDate = uploadDate
    }
}
