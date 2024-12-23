//
//  Account.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/23/24.
//

public struct Account: Codable, Sendable {
    public let accountID: String
    public let firstName: String
    public let lastName: String
    public let email: String
    
    public init(accountID: String, firstName: String, lastName: String, email: String) {
        self.accountID = accountID
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }
}
