import Vapor

// configures your application
public func configure(_ app: Application, mpc: PiController) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // register routes
    try routes(app, mpc: mpc)
}
