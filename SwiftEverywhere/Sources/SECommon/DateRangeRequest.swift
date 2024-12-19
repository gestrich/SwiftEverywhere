//
//  DateRangeRequest.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/15/24.
//

import Foundation

public struct DateRangeRequest: Codable, Sendable {
    public let startDate: Date
    public let endDate: Date
    
    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}
