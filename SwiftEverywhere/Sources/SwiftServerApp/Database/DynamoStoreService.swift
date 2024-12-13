//
//  DynamoStoreService.swift
//  HomeAPI
//
//  Created by Bill Gestrich on 11/28/24.
//

import Foundation
import NIO
import SotoDynamoDB

public struct DynamoStoreService {
    
    let db: DynamoDB
    let tableName: String
    
    // General
    
    public init(db: DynamoDB, tableName: String) {
        self.db = db
        self.tableName = tableName
    }
    
    // Assumes the items use iso 8601 dates for their sort key.
    func getItems<T: DynamoPartitioned>(type: T.Type, oldestDate: Date, latestDate: Date) async throws -> [T] {
        let oldestDateAsString = Utils.iso8601Formatter.string(from: oldestDate)
        let currentDateAsString = Utils.iso8601Formatter.string(from: latestDate)
        
        let items = try await getItems(
            partitionKey: T.partitionKey,
            partition: T.partition,
            sortKey: T.sortKey,
            startSort: oldestDateAsString,
            endSort: currentDateAsString
        ).items ?? []
        return try items.compactMap { item in
            return try DynamoDBDecoder().decode(T.self, from: item)
        }
    }
    
    public func getItems(
        partitionKey: String,
        partition: String,
        sortKey: String,
        startSort: String,
        endSort: String
    ) async throws -> DynamoDB.QueryOutput {
        let input = DynamoDB.QueryInput(
            expressionAttributeNames: ["#u" : partitionKey],
            expressionAttributeValues: [":u": .s(partition), ":d1" : .s(startSort), ":d2" : .s(endSort)],
            keyConditionExpression: "#u = :u AND \(sortKey) BETWEEN :d1 AND :d2",
            tableName: tableName
        )
        return try await db.query(input)
    }
    
    // MARK: Host
    
    public func getLatestHost() async throws -> Host? {
        // TODO: Need a way to get the last IP address without using time based query
        return try await self.getHostsInPastMinutes(60 * 60 * 24 * 365, referenceDate: Date()).last
    }
    
    public func storeHost(_ host: Host) async throws -> Host {
        let input = DynamoDB.PutItemCodableInput(
            item: host,
            tableName: tableName)
        _ = try await db.putItem(input)
        return host
    }
    
    public func getHostsInPastMinutes(_ minutes: Int, referenceDate: Date) async throws -> [Host] {
        let interval = TimeInterval(minutes) * -60
        let date = referenceDate.addingTimeInterval(interval)
        return try await self.getHostsSinceDate(oldestDate: date, latestDate: referenceDate)
    }
    
    public func getHostsSinceDate(oldestDate: Date, latestDate: Date) async throws -> [Host] {
        return try await getItems(type: Host.self, oldestDate: oldestDate, latestDate: latestDate)
    }
    
}

protocol DynamoPartitioned: Codable{
    static var partitionKey: String { get }
    static var partition: String { get }
    static var sortKey: String { get }
}
