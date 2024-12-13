//
//  Date+Utilities.swift
//
//
//  Created by Bill Gestrich on 12/9/20.
//

import Foundation


public struct Utils {
    public static let iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

extension Date {
    
    public var iso8601: String {
        Utils.iso8601Formatter.string(from: self)
    }
    
    public func adding(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
        
    }
}
