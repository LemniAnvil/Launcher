//
//  ModLoaderProtocol.swift
//  Launcher
//
//  Protocol for Minecraft mod loaders
//

import Foundation

/// Protocol defining the interface for all mod loaders
protocol ModLoaderProtocol {
    /// Returns the unique identifier of the mod loader (e.g., "fabric", "forge")
    func getId() -> String

    /// Returns the display name of the mod loader (e.g., "Fabric", "Forge")
    func getName() -> String

    /// Returns a list of all Minecraft versions that the mod loader supports
    /// - Parameter stableOnly: Only return stable versions and not snapshots
    func getMinecraftVersions(stableOnly: Bool) async throws -> [String]

    /// Returns all versions of the mod loader for a specific Minecraft version
    /// - Parameters:
    ///   - minecraftVersion: The Minecraft version to query
    ///   - stableOnly: Only return stable loader versions
    func getLoaderVersions(minecraftVersion: String, stableOnly: Bool) async throws -> [String]

    /// Returns the URL to download the installer
    /// - Parameters:
    ///   - minecraftVersion: The Minecraft version
    ///   - loaderVersion: The loader version
    func getInstallerUrl(minecraftVersion: String, loaderVersion: String) -> String

    /// Returns the version ID under which the mod loader will be installed
    /// - Parameters:
    ///   - minecraftVersion: The Minecraft version
    ///   - loaderVersion: The loader version
    func getInstalledVersion(minecraftVersion: String, loaderVersion: String) -> String
}

/// Mod loader manager that provides access to all available mod loaders
class ModLoaderManager {
    /// Default singleton using built-in ModLoader implementations
    static let shared = ModLoaderManager()

    private let modLoaders: [ModLoaderProtocol]

    /// Creates a ModLoaderManager instance
    /// - Parameter modLoaders: Optional array of ModLoaders for dependency injection.
    ///                         If nil, uses the default built-in implementations.
    ///                         Pass a custom array for unit testing.
    /// - Example:
    ///   ```swift
    ///   // Production - use singleton
    ///   let manager = ModLoaderManager.shared
    ///
    ///   // Unit testing - inject mock
    ///   let mockLoader = MockModLoader()
    ///   let testManager = ModLoaderManager(modLoaders: [mockLoader])
    ///   ```
    init(modLoaders: [ModLoaderProtocol]? = nil) {
        self.modLoaders = modLoaders ?? Self.createDefaultModLoaders()
    }

    /// Creates the default list of ModLoader implementations
    private static func createDefaultModLoaders() -> [ModLoaderProtocol] {
        return [
            FabricModLoader(),
            ForgeModLoader(),
            NeoForgeModLoader(),
            QuiltModLoader(),
        ]
    }

    /// Returns a list of all available mod loader IDs
    func listModLoaders() -> [String] {
        return modLoaders.map { $0.getId() }
    }

    /// Returns a list of all available mod loaders
    func getAllModLoaders() -> [ModLoaderProtocol] {
        return modLoaders
    }

    /// Returns the mod loader with the given ID
    /// - Parameter id: The mod loader ID
    /// - Throws: An error if the mod loader is not found
    func getModLoader(id: String) throws -> ModLoaderProtocol {
        guard let loader = modLoaders.first(where: { $0.getId() == id }) else {
            throw ModLoaderError.notFound(id)
        }
        return loader
    }

    /// Check if a mod loader with the given ID exists
    /// - Parameter id: The mod loader ID
    /// - Returns: true if the mod loader exists
    func hasModLoader(id: String) -> Bool {
        return modLoaders.contains { $0.getId() == id }
    }
}

/// Errors that can occur when working with mod loaders
enum ModLoaderError: LocalizedError {
    case notFound(String)
    case networkError(Error)
    case invalidResponse
    case unsupportedVersion(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Mod loader '\(id)' not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .unsupportedVersion(let version):
            return "Minecraft version '\(version)' is not supported"
        }
    }
}
