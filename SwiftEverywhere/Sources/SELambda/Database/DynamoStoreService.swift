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
    
    func getItemsInPastMinutes<T: Codable>(searchRequest: DynamoSearchRequest<T>, minutes: Int, referenceDate: Date) async throws -> [T] {
        let interval = TimeInterval(minutes) * -60
        let date = referenceDate.addingTimeInterval(interval)
        return try await getItems(searchRequest: searchRequest, oldestDate: date, latestDate: referenceDate)
    }
    
    // Assumes the items use iso 8601 dates for their sort key.
    func getItems<T: Codable>(searchRequest: DynamoSearchRequest<T>, oldestDate: Date, latestDate: Date) async throws -> [T] {
        let oldestDateAsString = Utils.iso8601Formatter.string(from: oldestDate)
        let currentDateAsString = Utils.iso8601Formatter.string(from: latestDate)
        
        let items = try await getItems(
            partitionKey: searchRequest.partitionKey,
            partition: searchRequest.partition,
            sortKey: searchRequest.sortKey,
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
    
    // MARK: DynamoHost
    
    func getLatest<T: Codable>(searchRequest: DynamoSearchRequest<T>) async throws -> T? {
        // TODO: Need a way to get the last without using time based query
        return try await getItemsInPastMinutes(searchRequest: searchRequest, minutes: 60 * 60 * 24 * 365, referenceDate: Date()).last
    }
    
    func store<T: Codable>(item: T) async throws -> T {
        let input = DynamoDB.PutItemCodableInput(
            item: item,
            tableName: tableName)
        _ = try await db.putItem(input)
        // TODO: Should return what was stored
        return item
    }
}

struct DynamoSearchRequest<T: Codable> {
    let partitionKey: String
    let partition: String
    let sortKey: String
    let outputType: T.Type
    
    init(partition: String, outputType: T.Type){
        self.partitionKey = "partition"
        self.partition = partition
        self.sortKey = "uploadDate"
        self.outputType = outputType
    }
}

