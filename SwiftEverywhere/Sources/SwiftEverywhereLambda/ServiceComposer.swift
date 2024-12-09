//
//  ServiceComposer.swift
//
//
//  Created by Bill Gestrich on 12/9/23.
//

import Foundation
import SECommon
import SotoS3
import SotoSecretsManager
import SwiftServerApp

/*
 Manages the lifecycle and configuration of your services.
 */

class ServiceComposer {
    
    let app: SwiftServerApp
    let awsClient: AWSClient
    let configurationService: ConfigurationService
    let cloudDataService: CloudDataStore
    let secretsService: SecretsService
    let piClientSource: () async throws -> PiClientAPI

    private static func getEnvironmentVariable(key: String) -> String? {
        guard let rawVal = getenv(key) else {
            return nil
        }

        guard let result = String(utf8String: rawVal) else {
            return nil
        }

        return result
    }

    init(eventLoop: EventLoop) {

        let awsClient: AWSClient
        let value = Self.getEnvironmentVariable(key: "MOCK_AWS_CREDENTIALS")
        if value == "true" {
            awsClient = AWSClient(credentialProvider: .static(accessKeyId: "admin", secretAccessKey: "password"), httpClientProvider: .createNew)
        } else {
            awsClient = AWSClient(httpClientProvider: .createNew)
        }

        self.awsClient = awsClient

        let secretsServiceAWS = SecretsServiceAWS(awsClient: awsClient)
        self.secretsService = SecretsServiceProduction(awsSecretsService: secretsServiceAWS)

        self.configurationService = ConfigurationService(secretsService: secretsService)

        let cloudStoreFactory = CloudStoreFactory(configurationService: configurationService, awsClient: awsClient)
        self.cloudDataService = CloudDataStoreProduction(cloudStoreFactory: cloudStoreFactory.createCloudStore)
        
        let piClientFactory = PiClientFactory(configurationService: configurationService)
        self.piClientSource = piClientFactory.createClientApiImplementation

        let app = SwiftServerApp(cloudDataStore: cloudDataService, piClientSource: piClientFactory.createClientApiImplementation)
        self.app = app
    }
    
    func shutdown() async throws {
        try await awsClient.shutdown()
    }
}

struct CloudStoreFactory {

    let configurationService: ConfigurationService
    let awsClient: AWSClient

    func createCloudStore() async throws -> CloudDataStore {
        let configuration = try await configurationService.s3Configuration()
        return CloudDataStoreS3(awsClient: awsClient, bucketName: configuration.bucketName, endpoint: configuration.endpoint)
    }
}

struct PiClientFactory {
    let configurationService: ConfigurationService

    func createClientApiImplementation() async throws -> PiClientAPI {
        let configuration = try await configurationService.piConfiguration()
        return PiClientAPIImplementation(baseURL: URL(string: configuration.url)!)
    }
}
