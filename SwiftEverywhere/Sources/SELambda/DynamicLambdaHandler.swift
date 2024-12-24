//
//  DynamicLambdaHandler.swift
//
//
//  Created by Bill Gestrich on 1/29/22.
//

import AWSLambdaRuntime
import Foundation
import NIO

public struct DynamicLambdaHandler: StreamingLambdaHandler {

    private let handlers: [AnyLambdaHandler]

    public init(handlers: [AnyLambdaHandler]){
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

public protocol EventLoopLambdaHandler<In> {
    associatedtype In: Codable
    associatedtype Out: Codable
    func handle(_ event: In, context: LambdaContext) async throws -> Out
}

public extension EventLoopLambdaHandler {
    func handle(byteBuffer: ByteBuffer, context: LambdaContext) async throws -> ByteBuffer {
        let decodedInput = try decodeInputByteBuffer(byteBuffer)
        let output = try await handle(decodedInput, context: context)
        return try encodeOutputToByteBuffer(output)
    }
    
    func erased() -> AnyLambdaHandler {
        return AnyLambdaHandler(handler: self)
    }
    
    func decodeInputByteBuffer(_ byteBuffer: ByteBuffer) throws -> In {
        return try JSONDecoder().decode(In.self, from: byteBuffer)
    }
    
    func encodeOutputToByteBuffer(_ output: Out) throws -> ByteBuffer {
        let data = try JSONEncoder().encode(output)
        return ByteBuffer(data: data)
    }
}

public struct AnyLambdaHandler {

    fileprivate let handlerBlock: (_ context: LambdaContext, _ byteBuffer: ByteBuffer) async throws -> ByteBuffer
    fileprivate let supportsInputBlock: (ByteBuffer) -> Bool

    public init(handler: any EventLoopLambdaHandler) {
        self.handlerBlock = { (context: LambdaContext, byteBuffer: ByteBuffer) async throws -> ByteBuffer in
            return try await handler.handle(byteBuffer: byteBuffer, context: context)
        }

        self.supportsInputBlock = { (byteBuffer: ByteBuffer) -> Bool in
            do {
                let _ = try handler.decodeInputByteBuffer(byteBuffer)
                return true
            } catch {
                return false
            }
        }
    }
    
    fileprivate func handle(context : LambdaContext, event: ByteBuffer) async throws -> ByteBuffer {
        return try await handlerBlock(context, event)
    }

    fileprivate func supportsInput(_ input: ByteBuffer) -> Bool {
        return supportsInputBlock(input)
    }
}

