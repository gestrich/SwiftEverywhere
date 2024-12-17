//
//  APIGatewayHandler.swift
//  SwiftLambda
//
//  Created by Bill Gestrich on 12/25/23.
//

import AWSLambdaEvents
import AWSLambdaHelpers
import AWSLambdaRuntime
import Foundation
import NIO
import NIOHelpers
import SECommon

struct APIGWHandler: EventLoopLambdaHandler {

    typealias In = APIGateway.Request
    typealias Out = APIGateway.Response

    //MARK: EventLoopLambdaHandler conformance

    func handle(context: Lambda.Context, event: APIGateway.Request) -> EventLoopFuture<APIGateway.Response> {
        return context.eventLoop.asyncFuture {
            return try await handle(context: context, event: event)
        }
    }

    //Async variant
    func handle(context: Lambda.Context, event: APIGateway.Request) async throws -> APIGateway.Response {
        //TODO: The Lambda.InitializationContext can hold resources that can be reused on every request.
        //It may be more performant to use that to hold onto our database connections.
        let services = ServiceComposer(eventLoop: context.eventLoop)

        do {
            let response = try await route(event: event, app: services.app)
//            try await services.shutdown()
            return response
        } catch {
            //We have to shut down out resources before they deallocate so we catch then rethrow
            print(String(reflecting: error))
//            try await services.shutdown()
            //Note that error always results in a 500 status code returned (expected)
            throw error
        }
    }

    func route(event: In, app: SwiftServerApp) async throws -> APIGateway.Response {

        let leadingPathPart = "" // Use this if you there a leading part in your path, like "api" or "stage"

        let urlComponents: [String]
        if !leadingPathPart.isEmpty {
            urlComponents = event.path.urlComponentsAfter(targetComponent: "stage")
        } else {
            urlComponents = event.path.split(separator: "/").map(String.init)
        }

        guard let firstComponent = urlComponents.first else {
            throw APIGWHandlerError.general(description: "No path available")
        }
        
        guard let componentAsAPIPath = PiClientAPIPaths(rawValue: firstComponent) else {
            throw APIGWHandlerError.general(description: "Unknown path: \(firstComponent)")
        }
        
        switch componentAsAPIPath {
        case .analogReading:
            switch event.httpMethod {
            case .GET:
                guard urlComponents.count > 1, let channel = Int(urlComponents[1]) else {
                    throw APIGWHandlerError.general(description: "Missing channel in \(event.httpMethod)")
                }
                return try await app.piClientSource().getAnalogReading(channel: channel).apiGatewayOkResponse()
            case .POST:
                guard urlComponents.count > 1, let channel = Int(urlComponents[1]) else {
                    throw APIGWHandlerError.general(description: "Missing channel in \(event.httpMethod)")
                }
                guard let bodyData = event.bodyData() else {
                    throw APIGWHandlerError.general(description: "Missing body data")
                }
                let reading = try jsonDecoder.decode(AnalogReading.self, from: bodyData)
                return try await app.updateAnalogReading(reading:reading).apiGatewayOkResponse()
            default:
                throw APIGWHandlerError.general(description: "Method not handled: \(event.httpMethod)")
            }
        case .analogReadings:
            switch event.httpMethod {
            case .POST:
                guard urlComponents.count > 1, let channel = Int(urlComponents[1]) else {
                    throw APIGWHandlerError.general(description: "Missing channel in \(event.httpMethod)")
                }
                guard let bodyData = event.bodyData() else {
                    throw APIGWHandlerError.general(description: "Missing body data")
                }
                let range = try jsonDecoder.decode(DateRangeRequest.self, from: bodyData)
                return try await app.getAnalogReadings(channel: channel, range: range).apiGatewayOkResponse()
            default:
                throw APIGWHandlerError.general(description: "Method not handled: \(event.httpMethod)")
            }
        case .host:
            switch event.httpMethod {
            case .GET:
                return try await app.getHost().apiGatewayOkResponse()
            case .POST:
                guard let bodyData = event.bodyData() else {
                    throw APIGWHandlerError.general(description: "Missing body data")
                }
                let host = try jsonDecoder.decode(Host.self, from: bodyData)
                return try await app.postHost(host).apiGatewayOkResponse()
            default:
                throw APIGWHandlerError.general(description: "Method not handled: \(event.httpMethod)")
            }
        case .led:
            switch event.httpMethod {
            case .GET:
                return try await app.getLEDState().apiGatewayOkResponse()
            case .POST:
                guard let bodyData = event.bodyData() else {
                    throw APIGWHandlerError.general(description: "Missing body data")
                }
                
                let ledState = try jsonDecoder.decode(LEDState.self, from: bodyData)
                return try await app.updateLEDState(ledState).apiGatewayOkResponse()
            default:
                throw APIGWHandlerError.general(description: "Method not handled: \(event.httpMethod)")
            }
        case .lightSensorReading:
            switch event.httpMethod {
            case .GET:
                return try await app.piClientSource().getLightSensorReading().apiGatewayOkResponse()
            case .POST:
                guard let bodyData = event.bodyData() else {
                    throw APIGWHandlerError.general(description: "Missing body data")
                }
                let reading = try jsonDecoder.decode(LightSensorReading.self, from: bodyData)
                return try await app.updateLightSensorReading(reading).apiGatewayOkResponse()
            default:
                throw APIGWHandlerError.general(description: "Method not handled: \(event.httpMethod)")
            }
        case .lightSensorReadings:
            switch event.httpMethod {
            case .POST:
                guard let bodyData = event.bodyData() else {
                    throw APIGWHandlerError.general(description: "Missing body data")
                }
                let range = try jsonDecoder.decode(DateRangeRequest.self, from: bodyData)
                return try await app.getLightSensorReadings(range: range).apiGatewayOkResponse()
            default:
                throw APIGWHandlerError.general(description: "Method not handled: \(event.httpMethod)")
            }
        }
    }
    
    var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

enum APIGWHandlerError: LocalizedError {
    case general (description: String)

    var errorDescription: String? {
        switch self {
        case .general(let description):
            return description
        }
    }
}

extension Encodable {
    // TODO: There is some overlap in the swift-server-utilities method name.
    func apiGatewayOkResponse() throws -> APIGateway.Response {
        return try createAPIGatewayJSONResponse(statusCode: .ok)
    }

    func createAPIGatewayJSONResponse(statusCode: HTTPResponseStatus) throws -> APIGateway.Response {

        guard let jsonData = try? jsonEncoder.encode(self) else {
            throw APIGWHandlerError.general(description: "Could not convert object to json data")
        }

        let jsonString = String(data: jsonData, encoding: .utf8)
        return APIGateway.Response(statusCode: statusCode, headers: ["Content-Type": "application/json"], body: jsonString)
    }
    
    var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension String {
    func urlComponentsAfter(targetComponent: String) -> [String] {
        let allParts = split(separator: "/")
        var partFound = false
        var result = [String]()
        for currComponent in allParts {
            if partFound {
                result.append(String(currComponent))
            }

            if currComponent == targetComponent {
                partFound = true
            }
        }

        return result
    }
}
