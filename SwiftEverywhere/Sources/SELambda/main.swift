//
//  LambdaHandler.swift
//
//
//  Created by Bill Gestrich on 10/23/21.
//

import AWSLambdaRuntime
import Foundation
import NIO

public struct LambdaHandler: StreamingLambdaHandler {

    private let handlers: [AnyLambdaHandler]

    public init(){
        let handlers: [AnyLambdaHandler] = [
            APIGWHandler().erased(),
            AuthorizerLambdaHandler().erased(),
        ]
        self.handlers = handlers
    }

    public func handle(
        _ event: ByteBuffer,
        responseWriter: some LambdaResponseStreamWriter,
        context: LambdaContext
    ) async throws {
        for handler in handlers {
            if handler.supportsInput(event) {
                let byteBuffer = try await handler.handle(context: context, event: event)
                try await responseWriter.write(byteBuffer)
                try await responseWriter.finish()
                /*
                 // Partial writes are available
                 for i in 1...10 {
                     // Send partial data
                     try await responseWriter.write(ByteBuffer(string: "\(i)\n"))
                     // Perform some long asynchronous work
                     try await Task.sleep(for: .milliseconds(1000))
                 }
                 */

                return
            }
        }

        throw DynamicLambdaHandler.unmatchedHandler
    }

    enum DynamicLambdaHandler: Error {
        case unmatchedHandler
    }
}


let runtime = LambdaRuntime.init(handler: LambdaHandler())
try await runtime.run()
