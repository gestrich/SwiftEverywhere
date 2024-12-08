import Logging
import NIOCore
import NIOPosix
import SEGPIO
import SwiftyGPIO
import Vapor

@main
enum Entrypoint {
    static func main() async throws {
        
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = try await Application.make(env)
        startGPIOServices(app: app)
        // This attempts to install NIO as the Swift Concurrency global executor.
        // You can enable it if you'd like to reduce the amount of context switching between NIO and Swift Concurrency.
        // Note: this has caused issues with some libraries that use `.wait()` and cleanly shutting down.
        // If enabled, you should be careful about calling async functions before this point as it can cause assertion failures.
        // let executorTakeoverSuccess = NIOSingletons.unsafeTryInstallSingletonPosixEventLoopGroupAsConcurrencyGlobalExecutor()
        // app.logger.debug("Tried to install SwiftNIO's EventLoopGroup as Swift's global concurrency executor", metadata: ["success": .stringConvertible(executorTakeoverSuccess)])
        
        do {
            try await configure(app)
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.execute()
        try await app.asyncShutdown()
    }
    
    static func startGPIOServices(app: Application) {
        let boardType = SupportedBoard.RaspberryPi4_2024
        // let ledExample = LEDExample(boardType: boardType)
        // try ledExample.start()
let mpcExample = MPCExample(
    boardType: boardType,
    pollingScheduler: { initialDelay, delay, task in
        app.eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .seconds(Int64(initialDelay)), delay: .seconds(Int64(delay))) { _ in
            task()
        }
    }
)
        mpcExample?.start()
    }
}
