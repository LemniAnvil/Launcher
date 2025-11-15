//
//  ForgeModLoader.swift
//  Launcher
//
//  Forge mod loader implementation
//

import Foundation

/// Forge mod loader implementation
class ForgeModLoader: ModLoaderProtocol {
    private let mavenMetadataUrl = "https://maven.minecraftforge.net/net/minecraftforge/forge/maven-metadata.xml"

    func getId() -> String {
        return "forge"
    }

    func getName() -> String {
        return "Forge"
    }

    func getMinecraftVersions(stableOnly: Bool) async throws -> [String] {
        let metadata = try await parseMavenMetadata()

        var versionDict: [String: Bool] = [:]

        for version in metadata.versions {
            // Forge versions are in format: "1.20.1-47.2.0"
            let components = version.split(separator: "-", maxSplits: 1)
            if components.count >= 1 {
                let minecraftVersion = String(components[0])
                versionDict[minecraftVersion] = true
            }
        }

        return Array(versionDict.keys)
    }

    func getLoaderVersions(minecraftVersion: String, stableOnly: Bool) async throws -> [String] {
        let metadata = try await parseMavenMetadata()

        var versionList: [String] = []

        for version in metadata.versions {
            let components = version.split(separator: "-", maxSplits: 1)
            if components.count == 2 {
                let mcVersion = String(components[0])
                let forgeVersion = String(components[1])

                if mcVersion == minecraftVersion {
                    versionList.append(forgeVersion)
                }
            }
        }

        return versionList
    }

    func getInstallerUrl(minecraftVersion: String, loaderVersion: String) -> String {
        let forgeVersion = "\(minecraftVersion)-\(loaderVersion)"
        return "https://maven.minecraftforge.net/net/minecraftforge/forge/\(forgeVersion)/forge-\(forgeVersion)-installer.jar"
    }

    func getInstalledVersion(minecraftVersion: String, loaderVersion: String) -> String {
        return "\(minecraftVersion)-forge-\(loaderVersion)"
    }

    // MARK: - Helper Methods

    private func parseMavenMetadata() async throws -> MavenMetadata {
        guard let url = URL(string: mavenMetadataUrl) else {
            throw ModLoaderError.invalidResponse
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let parser = MavenMetadataParser()
        return try parser.parse(data)
    }
}

// MARK: - Maven Metadata Parser

private struct MavenMetadata {
    let latest: String
    let versions: [String]
}

private class MavenMetadataParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentValue = ""
    private var latest = ""
    private var versions: [String] = []

    func parse(_ data: Data) throws -> MavenMetadata {
        let parser = XMLParser(data: data)
        parser.delegate = self

        guard parser.parse() else {
            throw ModLoaderError.invalidResponse
        }

        return MavenMetadata(latest: latest, versions: versions)
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        currentValue = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let trimmed = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "latest":
            latest = trimmed
        case "version":
            if !trimmed.isEmpty {
                versions.append(trimmed)
            }
        default:
            break
        }
    }
}
