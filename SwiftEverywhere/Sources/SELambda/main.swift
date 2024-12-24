//
//  LambdaHandler.swift
//
//
//  Created by Bill Gestrich on 10/23/21.
//

import AWSLambdaRuntime
import Foundation
import NIO

struct LambdaHandler: StreamingLambdaHandler {
    func handle(
        _ event: ByteBuffer,
        responseWriter: some LambdaResponseStreamWriter,
        context: LambdaContext
    ) async throws {
        let handlers: [AnyLambdaHandler] = [
            APIGWHandler().erased(),
            AuthorizerLambdaHandler().erased(),
        ]
        let dynamicHandler = DynamicLambdaHandler(handlers: handlers)
        try await dynamicHandler.handle(event, responseWriter: responseWriter, context: context)
    }
}

let runtime = LambdaRuntime.init(handler: LambdaHandler())
try await runtime.run()
