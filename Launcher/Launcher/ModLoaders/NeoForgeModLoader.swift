//
//  NeoForgeModLoader.swift
//  Launcher
//
//  NeoForge mod loader implementation
//

import Foundation

/// NeoForge mod loader implementation
class NeoForgeModLoader: ModLoaderProtocol {
    private let apiUrl = "https://maven.neoforged.net/api/maven/versions/releases/net/neoforged/neoforge"
    private lazy var versionRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "^\\d+\\.\\d+")
    }()

    func getId() -> String {
        return "neoforge"
    }

    func getName() -> String {
        return "NeoForge"
    }

    func getMinecraftVersions(stableOnly: Bool) async throws -> [String] {
        guard let url = URL(string: apiUrl) else {
            throw ModLoaderError.invalidResponse
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(NeoForgeVersionResponse.self, from: data)

        var versionDict: [String: Bool] = [:]

        for version in response.versions {
            // Skip beta versions (starting with "0.")
            if version.hasPrefix("0.") {
                continue
            }

            // Extract the Minecraft version part using regex
            guard let regex = versionRegex else { continue }
            if let match = regex.firstMatch(
                in: version,
                range: NSRange(version.startIndex..., in: version)
            ) {
                if let range = Range(match.range, in: version) {
                    let mcVersionPart = String(version[range])
                    let normalized = normalizeMinecraftVersion(mcVersionPart)
                    versionDict[normalized] = true
                }
            }
        }

        return Array(versionDict.keys)
    }

    func getLoaderVersions(minecraftVersion: String, stableOnly: Bool) async throws -> [String] {
        guard let url = URL(string: apiUrl) else {
            throw ModLoaderError.invalidResponse
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(NeoForgeVersionResponse.self, from: data)

        var versionList: [String] = []

        for version in response.versions {
            // Skip beta versions if requested
            if stableOnly && version.contains("beta") {
                continue
            }

            // Extract the Minecraft version part
            guard let regex = versionRegex else { continue }
            if let match = regex.firstMatch(
                in: version,
                range: NSRange(version.startIndex..., in: version)
            ) {
                if let range = Range(match.range, in: version) {
                    let mcVersionPart = String(version[range])
                    let normalized = normalizeMinecraftVersion(mcVersionPart)

                    if normalized == minecraftVersion {
                        versionList.append(version)
                    }
                }
            }
        }

        // API returns versions from oldest to newest, reverse to get newest first
        versionList.reverse()

        return versionList
    }

    func getInstallerUrl(minecraftVersion: String, loaderVersion: String) -> String {
        return "https://maven.neoforged.net/releases/net/neoforged/neoforge/\(loaderVersion)/neoforge-\(loaderVersion)-installer.jar"
    }

    func getInstalledVersion(minecraftVersion: String, loaderVersion: String) -> String {
        return "neoforge-\(loaderVersion)"
    }

    // MARK: - Helper Methods

    /// Converts NeoForge version format to standard Minecraft version
    /// Example: "20.1" -> "1.20.1", "20.1.0" -> "1.20.1"
    private func normalizeMinecraftVersion(_ version: String) -> String {
        let withoutTrailingZero = version.hasSuffix(".0") ? String(version.dropLast(2)) : version
        return "1.\(withoutTrailingZero)"
    }
}

// MARK: - Data Models

private struct NeoForgeVersionResponse: Codable {
    let versions: [String]
}
