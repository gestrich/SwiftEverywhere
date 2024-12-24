//
//  File.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/24/24.
//

import Foundation

import AWSLambdaRuntime
import Foundation
import NIO

public protocol DynamicLambdaHandler<In> {
    associatedtype In: Codable
    associatedtype Out: Codable
    func handle(_ event: In, context: LambdaContext) async throws -> Out
}

public extension DynamicLambdaHandler {
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

    public init(handler: any DynamicLambdaHandler) {
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
    
    func handle(context : LambdaContext, event: ByteBuffer) async throws -> ByteBuffer {
        return try await handlerBlock(context, event)
    }

    func supportsInput(_ input: ByteBuffer) -> Bool {
        return supportsInputBlock(input)
    }
}
