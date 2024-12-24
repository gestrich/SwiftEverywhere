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

public struct AuthorizerLambdaHandler: DynamicLambdaHandler {
    public typealias In = AuthRequest
    public typealias Out = AuthResponse

    //MARK: DynamicLambdaHandler conformance
    
    public func handle(_ event: AuthRequest, context: AWSLambdaRuntimeCore.LambdaContext) async throws -> AuthResponse {
//        context.logger.log(level: .critical, "AuthRequest token = \(event.authorizationToken)")

        let services = ServiceComposer()
//        let app = services.app

        do {
            let response = generatePolicy(principalId: event.authorizationToken, effect: event.authorizationToken  == "12345" ? "Allow": "Deny", resource: event.methodArn)
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
        let context = ["principalId": principalId]
        return AuthResponse(principalId: principalId, policyDocument: policyDocument, context: context)
    }
}

// As a REST API, this uses the 1.0 format here:
// https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-lambda-authorizer.html
public struct AuthRequest: Codable {
    public let authorizationToken: String
    public let methodArn: String
}
public struct AuthResponse: Codable {
    public let principalId: String
    public let policyDocument: PolicyDocument
    public let context: [String: String]
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
