//
//  QuiltModLoader.swift
//  Launcher
//
//  Quilt mod loader implementation
//  Quilt uses a very similar API structure to Fabric
//

import Foundation

/// Quilt mod loader implementation
class QuiltModLoader: ModLoaderProtocol {
    private let mavenUrl = "https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer"
    private let gameUrl = "https://meta.quiltmc.org/v3/versions/game"
    private let loaderUrl = "https://meta.quiltmc.org/v3/versions/loader"
    private let loaderName = "quilt"

    func getId() -> String {
        return "quilt"
    }

    func getName() -> String {
        return "Quilt"
    }

    func getMinecraftVersions(stableOnly: Bool) async throws -> [String] {
        guard let url = URL(string: gameUrl) else {
            throw ModLoaderError.invalidResponse
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let versions = try JSONDecoder().decode([QuiltGameVersion].self, from: data)

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
        let loaders = try JSONDecoder().decode([QuiltLoaderVersion].self, from: data)

        var versionList: [String] = []
        for loader in loaders {
            // Skip unstable versions if requested
            if stableOnly {
                let isStable = loader.stable
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
        // For simplicity, we'll use a reasonable default
        let installerVersion = "0.10.2" // This should be fetched from maven-metadata.xml
        return "\(mavenUrl)/\(installerVersion)/quilt-installer-\(installerVersion).jar"
    }

    func getInstalledVersion(minecraftVersion: String, loaderVersion: String) -> String {
        return "\(loaderName)-loader-\(loaderVersion)-\(minecraftVersion)"
    }
}

// MARK: - Data Models

private struct QuiltGameVersion: Codable {
    let version: String
    let stable: Bool
}

private struct QuiltLoaderVersion: Codable {
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
