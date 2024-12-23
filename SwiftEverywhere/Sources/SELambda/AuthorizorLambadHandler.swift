//
//  AuthorizerLambdaHandler.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/23/24.
//

import AWSLambdaEvents
import AWSLambdaRuntime
import Foundation
import NIO

public struct AuthorizerLambdaHandler: EventLoopLambdaHandler {
    
    public typealias In = AuthRequest
    public typealias Out = AuthResponse

    //MARK: EventLoopLambdaHandler conformance

    public func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        let future = context.eventLoop.asyncFuture {
            return try await handle(context: context, event: event)
        }

        return future
    }


    //Async variant
    func handle(context: Lambda.Context, event: In) async throws -> Out {
        
        context.logger.log(level: .critical, "Cloud Watch (CreateAnalysisRequest) event received")

        let services = ServiceComposer(eventLoop: context.eventLoop)
        let app = services.app

        do {
            let response = try await generatePolicy(principalId: event.authorizationToken, effect: "Allow", resource: event.methodArn)
            try await services.shutdown()
            return response
        } catch {
            //We have to shut down out resources before they deallocate so we catch then rethrow
            try await services.shutdown()
            print(String(reflecting: error))
            //Note that error always results in a 500 status code returned (expected)
            throw error
        }
    }
    
    func generatePolicy(principalId: String, effect: String, resource: String?) -> AuthResponse {
        let statement = PolicyStatement(Action: "execute-api:Invoke", Effect: effect, Resource: resource)
        let policyDocument = PolicyDocument(Version: "2012-10-17", Statement: [statement])
        return AuthResponse(principalId: principalId, policyDocument: policyDocument)
    }
}

public struct AuthRequest: Codable {
    public let authorizationToken: String
    public let methodArn: String
}
public struct AuthResponse: Codable {
    public let principalId: String
    public let policyDocument: PolicyDocument
}

public struct PolicyDocument: Codable {
    public let Version: String
    public let Statement: [PolicyStatement]
}

public struct PolicyStatement: Codable {
    public let Action: String
    public let Effect: String
    public let Resource: String?
}
