//
//  NeoForgeModLoader.swift
//  Launcher
//
//  NeoForge mod loader implementation
//
//

import Foundation

/// NeoForge mod loader implementation
class NeoForgeModLoader: ModLoaderProtocol {
    private let apiUrl = "https://meta.prismlauncher.org/v1/net.neoforged/index.json"

    func getId() -> String {
        return "neoforge"
    }

    func getName() -> String {
        return "NeoForge"
    }

    func getMinecraftVersions(stableOnly: Bool) async throws -> [String] {
        let response = try await fetchMetadata()

        var versionDict: [String: Bool] = [:]

        for version in response.versions {
            // Find the Minecraft dependency
            if let mcRequirement = version.requires.first(where: { $0.uid == "net.minecraft" }),
               let mcVersion = mcRequirement.equals {
                versionDict[mcVersion] = true
            }
        }

        // Return sorted versions (descending)
        return Array(versionDict.keys).sorted { $0.compare($1, options: .numeric) == .orderedDescending }
    }

    func getLoaderVersions(minecraftVersion: String, stableOnly: Bool) async throws -> [String] {
        let response = try await fetchMetadata()

        var versionList: [String] = []

        for version in response.versions {
            // Check if this loader version is for the requested Minecraft version
            if let mcRequirement = version.requires.first(where: { $0.uid == "net.minecraft" }),
               mcRequirement.equals == minecraftVersion {

                // Skip unstable versions if requested
                // NeoForge versions often have -beta suffix, but some might be considered stable.
                // For now, we'll trust the user's preference if they want stable only.
                if stableOnly && version.type != "release" {
                    continue
                }

                versionList.append(version.version)
            }
        }

        return versionList
    }

    func getInstallerUrl(minecraftVersion: String, loaderVersion: String) -> String {
        // Construct Maven URL for the installer
        // Example: https://maven.neoforged.net/releases/net/neoforged/neoforge/20.2.86/neoforge-20.2.86-installer.jar
        return "https://maven.neoforged.net/releases/net/neoforged/neoforge/\(loaderVersion)/neoforge-\(loaderVersion)-installer.jar"
    }

    func getInstalledVersion(minecraftVersion: String, loaderVersion: String) -> String {
        return "neoforge-\(loaderVersion)"
    }

    // MARK: - Helper Methods

    private func fetchMetadata() async throws -> PrismVersionIndex {
        guard let url = URL(string: apiUrl) else {
            throw ModLoaderError.invalidResponse
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PrismVersionIndex.self, from: data)
    }
}

// MARK: - Data Models

private struct PrismVersionIndex: Codable {
    let versions: [PrismVersion]
}

private struct PrismVersion: Codable {
    let version: String
    let type: String?
    let requires: [PrismRequirement]
    let releaseTime: String
}

private struct PrismRequirement: Codable {
    let uid: String
    let equals: String?
}
