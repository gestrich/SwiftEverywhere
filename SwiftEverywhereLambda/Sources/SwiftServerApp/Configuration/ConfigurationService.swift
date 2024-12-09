//
//  ConfigurationService.swift
//
//
//  Created by Bill Gestrich on 12/16/23.
//

import Foundation

public class ConfigurationService {

    private let configFileURL = Configuration.localConfigFileURL()
    private let secretsService: SecretsService

    public init(secretsService: SecretsService) {
        self.secretsService = secretsService
    }

    private func configurationFromFile() async throws -> Configuration? {
        guard FileManager.default.fileExists(atPath: configFileURL.path) else {
            return nil
        }

        return try Configuration.loadConfiguration(fileURL: configFileURL)
    }

    // MARK: AWS Credentials
    
    // MARK: Pi
    
    public func piConfiguration() async throws -> PiConfiguration {
        if let configuration = try await configurationFromFile() {
            return configuration.piConfiguration
        } else {
            return try await piConfigurationFromEnvironment()
        }
    }
    
    private func piConfigurationFromEnvironment() async throws -> PiConfiguration {
        let piURL = try await secretsService.getSecret(identifier: "pi-url")
        return PiConfiguration(url: piURL)
    }

    //MARK: S3

    public func s3Configuration() async throws -> S3Configuration {
        if let configuration = try await configurationFromFile() {
            return configuration.s3
        } else {
            return try s3ConfigurationFromEnvironment()
        }
    }

    private func s3ConfigurationFromEnvironment() throws -> S3Configuration {
        let bucketName = try getEnvironmentVariable(key: "S3_BUCKET_NAME")
        return S3Configuration(bucketName: bucketName, endpoint: nil) //endpoint not yet supported from env variables.
    }

    //MARK: Util

    private enum ConfigurationError: LocalizedError {
        case missingFromEnvVariables(String)
        case typeConversion(String)

        var errorDescription: String? {
            switch self {
            case .missingFromEnvVariables(let message):
                return message
            case .typeConversion(let message):
                return message
            }
        }
    }

    private func getEnvironmentVariable(key: String) throws -> String {
        guard let rawVal = getenv(key) else {
            throw ConfigurationError.missingFromEnvVariables(key)
        }

        guard let result = String(utf8String: rawVal) else {
            throw ConfigurationError.typeConversion("Could not convert environment variable to string. Variable: \(key) Value: \(rawVal)")
        }

        return result
    }
}
