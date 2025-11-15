//
//  FabricModLoader.swift
//  Launcher
//
//  Fabric mod loader implementation
//

import Foundation

/// Fabric mod loader implementation
class FabricModLoader: ModLoaderProtocol {
    private let mavenUrl = "https://maven.fabricmc.net/net/fabricmc/fabric-installer"
    private let gameUrl = "https://meta.fabricmc.net/v2/versions/game"
    private let loaderUrl = "https://meta.fabricmc.net/v2/versions/loader"
    private let loaderName = "fabric"

    func getId() -> String {
        return "fabric"
    }

    func getName() -> String {
        return "Fabric"
    }

    func getMinecraftVersions(stableOnly: Bool) async throws -> [String] {
        guard let url = URL(string: gameUrl) else {
            throw ModLoaderError.invalidResponse
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let versions = try JSONDecoder().decode([FabricGameVersion].self, from: data)

        var versionList: [String] = []
        for version in versions {
            if !version.stable && stableOnly {
                continue
            }
            versionList.append(version.version)
        }

        return versionList
    }

    func getLoaderVersions(minecraftVersion: String, stableOnly: Bool) async throws -> [String] {
        guard let url = URL(string: loaderUrl) else {
            throw ModLoaderError.invalidResponse
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let loaders = try JSONDecoder().decode([FabricLoaderVersion].self, from: data)

        var versionList: [String] = []
        for loader in loaders {
            // Skip unstable versions if requested
            if stableOnly {
                let isStable = loader.stable ?? true
                if !isStable || loader.version.contains("beta") {
                    continue
                }
            }
            versionList.append(loader.version)
        }

        return versionList
    }

    func getInstallerUrl(minecraftVersion: String, loaderVersion: String) -> String {
        // Note: In production, you would parse the maven-metadata.xml to get the latest installer version
        // For simplicity, we'll use a reasonable default or the latest known version
        let installerVersion = "1.0.1" // This should be fetched from maven-metadata.xml
        return "\(mavenUrl)/\(installerVersion)/fabric-installer-\(installerVersion).jar"
    }

    func getInstalledVersion(minecraftVersion: String, loaderVersion: String) -> String {
        return "\(loaderName)-loader-\(loaderVersion)-\(minecraftVersion)"
    }
}

// MARK: - Data Models

private struct FabricGameVersion: Codable {
    let version: String
    let stable: Bool
}

private struct FabricLoaderVersion: Codable {
    let version: String
    let stable: Bool

    enum CodingKeys: String, CodingKey {
        case version
        case stable
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)
        stable = try container.decodeIfPresent(Bool.self, forKey: .stable) ?? false
    }
}
